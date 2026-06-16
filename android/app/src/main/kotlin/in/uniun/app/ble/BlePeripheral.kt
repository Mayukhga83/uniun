package `in`.uniun.app.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import java.util.ArrayDeque

/**
 * The peripheral role: advertises the UNIUN service (+ our dial token), serves the
 * GATT characteristic, and exposes each connected central as a [BlePeerChannel].
 * Receives via characteristic-write requests; sends via notifications.
 *
 * Notifications are serialized **globally** (one in flight across all centrals)
 * because pre-Android-13 the characteristic value is shared state — this avoids a
 * cross-device race while staying simple (BLE throughput is low anyway).
 */
@SuppressLint("MissingPermission")
class BlePeripheral(
    private val context: Context,
    private val manager: BluetoothManager,
    private val adapter: BluetoothAdapter,
    private val myToken: ByteArray,
    private val events: BleController,
) {
    private val main = Handler(Looper.getMainLooper())
    private var server: BluetoothGattServer? = null
    private var characteristic: BluetoothGattCharacteristic? = null

    private val mtuByAddress = HashMap<String, Int>()
    private val reassemblers = HashMap<String, BleFragmenter.Reassembler>()
    private val devices = HashMap<String, BluetoothDevice>()
    private val ready = HashSet<String>()

    // Global notification queue: (device, fragment), one in flight.
    private val outQueue = ArrayDeque<Pair<BluetoothDevice, ByteArray>>()
    private var notifying = false

    fun start() {
        val gattServer = manager.openGattServer(context, serverCallback) ?: return
        server = gattServer
        val ch = BluetoothGattCharacteristic(
            BleUuids.CHARACTERISTIC,
            BluetoothGattCharacteristic.PROPERTY_WRITE or
                BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE or
                BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        ch.addDescriptor(
            BluetoothGattDescriptor(
                BleUuids.CCC,
                BluetoothGattDescriptor.PERMISSION_READ or
                    BluetoothGattDescriptor.PERMISSION_WRITE,
            ),
        )
        val service = BluetoothGattService(
            BleUuids.SERVICE, BluetoothGattService.SERVICE_TYPE_PRIMARY,
        )
        service.addCharacteristic(ch)
        gattServer.addService(service)
        characteristic = ch
        startAdvertising()
    }

    fun stop() {
        try { adapter.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback) } catch (_: Exception) {}
        main.post {
            val toDrop = devices.keys.toList()
            for (address in toDrop) drop(address)
            try { server?.close() } catch (_: Exception) {}
            server = null
            outQueue.clear()
            notifying = false
        }
    }

    private fun startAdvertising() {
        val advertiser = adapter.bluetoothLeAdvertiser ?: return
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .build()
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(BleUuids.SERVICE))
            .addManufacturerData(BleUuids.MANUFACTURER_ID, myToken)
            .build()
        try {
            advertiser.startAdvertising(settings, data, advertiseCallback)
        } catch (e: Exception) {
            Log.w(BleController.TAG, "peripheral: advertise threw: $e")
        }
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.d(BleController.TAG, "peripheral: advertising")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.w(BleController.TAG, "peripheral: advertise failed code=$errorCode")
        }
    }

    private val serverCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            val address = device.address
            main.post {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    devices[address] = device
                    reassemblers[address] = BleFragmenter.Reassembler()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    drop(address)
                }
            }
        }

        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) {
            mtuByAddress[device.address] = mtu
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray,
        ) {
            if (responseNeeded) {
                server?.sendResponse(device, requestId, 0 /* GATT_SUCCESS */, offset, null)
            }
            main.post {
                val whole = reassemblers[device.address]?.receive(value) ?: return@post
                events.onMessage(device.address, whole)
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray,
        ) {
            if (responseNeeded) {
                server?.sendResponse(device, requestId, 0 /* GATT_SUCCESS */, offset, null)
            }
            // The central enabling notifications signals the link is ready.
            if (descriptor.uuid == BleUuids.CCC) {
                main.post { markReady(device) }
            }
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            main.post {
                notifying = false
                pump()
            }
        }
    }

    private fun markReady(device: BluetoothDevice) {
        val address = device.address
        if (!ready.add(address)) return
        val channel = PeripheralPeerChannel(device)
        events.onPeerUp(address, channel)
    }

    private fun drop(address: String) {
        val device = devices.remove(address)
        reassemblers.remove(address)
        mtuByAddress.remove(address)
        val wasReady = ready.remove(address)
        // Purge any queued fragments for this device.
        outQueue.removeAll { it.first.address == address }
        if (wasReady && device != null) events.onPeerDown(address)
    }

    private fun pump() {
        if (notifying) return
        val (device, chunk) = outQueue.poll() ?: return
        val ch = characteristic ?: return
        notifying = true
        notify(device, ch, chunk)
    }

    @Suppress("DEPRECATION")
    private fun notify(device: BluetoothDevice, ch: BluetoothGattCharacteristic, chunk: ByteArray) {
        val srv = server ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                srv.notifyCharacteristicChanged(device, ch, false, chunk)
            } else {
                ch.value = chunk
                srv.notifyCharacteristicChanged(device, ch, false)
            }
        } catch (_: Exception) {
            notifying = false
        }
    }

    /** Peripheral → central channel: fragments into the global notify queue. */
    inner class PeripheralPeerChannel(
        private val device: BluetoothDevice,
    ) : BlePeerChannel {
        private var msgId = 0

        override fun sendMessage(message: ByteArray) {
            main.post {
                val mtu = mtuByAddress[device.address] ?: 23
                val id = (msgId++) and 0xFFFF
                for (chunk in BleFragmenter.fragment(message, id, mtu)) {
                    outQueue.add(device to chunk)
                }
                pump()
            }
        }

        override fun close() {
            main.post {
                try {
                    server?.cancelConnection(device)
                } catch (_: Exception) {}
                drop(device.address)
            }
        }
    }
}
