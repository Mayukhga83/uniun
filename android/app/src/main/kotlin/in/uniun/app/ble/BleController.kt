package `in`.uniun.app.ble

import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentHashMap

/**
 * The BLE byte-pipe registered on the **mesh engine**. It bridges the Dart
 * `BleConnector`/`BleLink` to the native dual-role GATT stack:
 *   * MethodChannel `in.uniun.app/ble` — `start` / `stop` / `send` / `disconnect`,
 *   * EventChannel  `in.uniun.app/ble/events` — `peerUp` / `peerDown` / `message`.
 *
 * It owns the per-launch dial token, the central + peripheral roles, and the
 * peerId → [BlePeerChannel] registry that routes `send`/`disconnect`. All Dart-facing
 * events are posted to the main thread (the EventSink is main-thread only).
 */
class BleController(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val main = Handler(Looper.getMainLooper())
    private val methodChannel = MethodChannel(messenger, "in.uniun.app/ble")
    private val eventChannel = EventChannel(messenger, "in.uniun.app/ble/events")
    private var sink: EventChannel.EventSink? = null

    private val token = randomToken()
    private val peers = ConcurrentHashMap<String, BlePeerChannel>()

    private var central: BleCentral? = null
    private var peripheral: BlePeripheral? = null
    private var started = false

    init {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> { start(); result.success(null) }
                "stop" -> { stop(); result.success(null) }
                "send" -> {
                    val peerId = call.argument<String>("peerId")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (peerId != null && bytes != null) peers[peerId]?.sendMessage(bytes)
                    result.success(null)
                }
                "disconnect" -> {
                    val peerId = call.argument<String>("peerId")
                    if (peerId != null) peers[peerId]?.close()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
                sink = eventSink
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    private fun start() {
        if (started) return
        val manager = context.getSystemService(BluetoothManager::class.java) ?: return
        val adapter = manager.adapter
        if (adapter == null || !adapter.isEnabled) {
            Log.w(TAG, "start: bluetooth adapter null/off")
            return
        }
        started = true
        val tokenHex = token.joinToString("") { "%02x".format(it) }
        Log.d(TAG, "start: dual-role BLE, token=$tokenHex")
        central = BleCentral(context, adapter, token, this).also { it.start() }
        peripheral = BlePeripheral(context, manager, adapter, token, this).also { it.start() }
    }

    private fun stop() {
        if (!started) return
        started = false
        Log.d(TAG, "stop")
        central?.stop(); central = null
        peripheral?.stop(); peripheral = null
        for (c in peers.values.toList()) c.close()
        peers.clear()
    }

    /** Releases the channels (called when the mesh engine is destroyed). */
    fun dispose() {
        stop()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ── called by the central/peripheral roles ──────────────────────────────────
    fun onPeerUp(peerId: String, channel: BlePeerChannel) {
        peers[peerId] = channel
        Log.d(TAG, "peerUp $peerId")
        emit(mapOf("type" to "peerUp", "peerId" to peerId))
    }

    fun onMessage(peerId: String, data: ByteArray) {
        emit(mapOf("type" to "message", "peerId" to peerId, "bytes" to data))
    }

    fun onPeerDown(peerId: String) {
        peers.remove(peerId)
        Log.d(TAG, "peerDown $peerId")
        emit(mapOf("type" to "peerDown", "peerId" to peerId))
    }

    private fun emit(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }

    companion object {
        const val TAG = "MESH/BLE"
    }
}
