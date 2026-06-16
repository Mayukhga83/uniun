package `in`.uniun.app.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import java.util.ArrayDeque

/**
 * The central role: scans for UNIUN peripherals, applies dial arbitration (only the
 * higher-token side connects), opens a GATT connection, negotiates the MTU, enables
 * notifications, and exposes each connection as a [BlePeerChannel]. Sends by writing
 * fragments to the peer's characteristic (one in flight, waiting for the write ACK);
 * receives via characteristic-change notifications.
 */
@SuppressLint("MissingPermission")
class BleCentral(
    private val context: Context,
    private val adapter: BluetoothAdapter,
    private val myToken: ByteArray,
    private val events: BleController,
) {
    private val main = Handler(Looper.getMainLooper())
    private val connecting = HashSet<String>()
    private val channels = HashMap<String, CentralPeerChannel>()

    fun start() {
        val scanner = adapter.bluetoothLeScanner ?: return
        val filters = listOf(
            ScanFilter.Builder().setServiceUuid(ParcelUuid(BleUuids.SERVICE)).build(),
        )
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        try {
            scanner.startScan(filters, settings, scanCallback)
            Log.d(BleController.TAG, "central: scanning")
        } catch (e: Exception) {
            Log.w(BleController.TAG, "central: scan failed: $e")
        }
    }

    fun stop() {
        try {
            adapter.bluetoothLeScanner?.stopScan(scanCallback)
        } catch (_: Exception) {}
        main.post {
            for (c in channels.values.toList()) c.close()
            channels.clear()
            connecting.clear()
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            val address = device.address ?: return
            if (!shouldDial(extractToken(result), address)) return
            main.post {
                if (!connecting.add(address)) return@post
                Log.d(BleController.TAG, "central: dialing $address")
                try {
                    device.connectGatt(
                        context, false, gattCallback, BluetoothDevice.TRANSPORT_LE,
                    )
                } catch (e: Exception) {
                    Log.w(BleController.TAG, "central: connect failed: $e")
                    connecting.remove(address)
                }
            }
        }
    }

    // The dial token rides manufacturer data on Android peers, or the local name on
    // Apple peers (CoreBluetooth can't advertise manufacturer data) — read whichever.
    private fun extractToken(result: ScanResult): ByteArray? {
        val rec = result.scanRecord ?: return null
        rec.getManufacturerSpecificData(BleUuids.MANUFACTURER_ID)?.let {
            if (it.size >= 4) return it.copyOfRange(0, 4)
        }
        val name = rec.deviceName
        if (name != null && name.length == 8) return hexToBytes(name)
        return null
    }

    // Only the higher-token side dials (the other will be our peripheral). Ties break
    // on address so exactly one side connects.
    private fun shouldDial(peerToken: ByteArray?, address: String): Boolean {
        if (peerToken == null) return false
        val cmp = compareTokens(myToken, peerToken)
        if (cmp != 0) return cmp > 0
        val mine = adapter.address ?: return false
        return mine > address
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> gatt.requestMtu(517)
                BluetoothProfile.STATE_DISCONNECTED -> onDisconnected(gatt)
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            mtuByAddress[gatt.device.address] = mtu
            gatt.discoverServices()
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            val service = gatt.getService(BleUuids.SERVICE)
            val ch = service?.getCharacteristic(BleUuids.CHARACTERISTIC)
            val ccc = ch?.getDescriptor(BleUuids.CCC)
            if (ch == null || ccc == null) {
                gatt.disconnect()
                return
            }
            gatt.setCharacteristicNotification(ch, true)
            writeDescriptor(gatt, ccc, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int,
        ) {
            val address = gatt.device.address
            val ch = descriptor.characteristic
            val mtu = mtuByAddress[address] ?: 23
            val channel = CentralPeerChannel(address, gatt, ch, mtu)
            channels[address] = channel
            events.onPeerUp(address, channel)
        }

        // API 33+ inbound notification.
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            channels[gatt.device.address]?.onInbound(value)
        }

        // Pre-33 inbound notification.
        @Deprecated("Deprecated in Java")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                channels[gatt.device.address]?.onInbound(characteristic.value)
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            channels[gatt.device.address]?.onWriteComplete()
        }

        private fun onDisconnected(gatt: BluetoothGatt) {
            val address = gatt.device.address
            main.post {
                connecting.remove(address)
                mtuByAddress.remove(address)
                val ch = channels.remove(address)
                try { gatt.close() } catch (_: Exception) {}
                if (ch != null) events.onPeerDown(address)
            }
        }
    }

    private val mtuByAddress = HashMap<String, Int>()

    @Suppress("DEPRECATION")
    private fun writeDescriptor(
        gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, value: ByteArray,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeDescriptor(descriptor, value)
        } else {
            descriptor.value = value
            gatt.writeDescriptor(descriptor)
        }
    }

    /** Central → peripheral channel: fragments + writes, one fragment in flight. */
    inner class CentralPeerChannel(
        private val address: String,
        private val gatt: BluetoothGatt,
        private val characteristic: BluetoothGattCharacteristic,
        private val mtu: Int,
    ) : BlePeerChannel {
        private val queue = ArrayDeque<ByteArray>()
        private val reassembler = BleFragmenter.Reassembler()
        private var sending = false
        private var msgId = 0
        private var closed = false

        override fun sendMessage(message: ByteArray) {
            main.post {
                if (closed) return@post
                val id = (msgId++) and 0xFFFF
                queue.addAll(BleFragmenter.fragment(message, id, mtu))
                pump()
            }
        }

        fun onInbound(fragment: ByteArray) {
            val whole = reassembler.receive(fragment) ?: return
            events.onMessage(address, whole)
        }

        fun onWriteComplete() {
            main.post {
                sending = false
                pump()
            }
        }

        private fun pump() {
            if (sending || closed) return
            val chunk = queue.poll() ?: return
            sending = true
            writeChunk(chunk)
        }

        @Suppress("DEPRECATION")
        private fun writeChunk(chunk: ByteArray) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    gatt.writeCharacteristic(
                        characteristic, chunk,
                        BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT,
                    )
                } else {
                    characteristic.writeType =
                        BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                    characteristic.value = chunk
                    gatt.writeCharacteristic(characteristic)
                }
            } catch (_: Exception) {
                close()
            }
        }

        override fun close() {
            if (closed) return
            closed = true
            queue.clear()
            try { gatt.disconnect() } catch (_: Exception) {}
        }
    }
}
