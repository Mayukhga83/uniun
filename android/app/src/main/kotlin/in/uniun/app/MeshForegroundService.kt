package `in`.uniun.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import `in`.uniun.app.ble.BleController
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the headless mesh [FlutterEngine] so the offline mesh keeps running while
 * the app is backgrounded. The foreground service keeps the *process* alive, which
 * keeps this engine (its own Dart isolate, its own Isar, and the LAN/BLE channels)
 * alive — the mesh `MeshEngineHost` runs entirely inside it.
 *
 * Phase A hosts the LAN mesh and uses the `dataSync` foreground-service type. Phase
 * B (BLE) switches this to `connectedDevice` once the Bluetooth permissions are
 * present (that type requires holding a connected-device permission on Android 14+).
 */
class MeshForegroundService : Service() {
    private var engine: FlutterEngine? = null
    private var bleController: BleController? = null
    private var tearingDown = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopGracefully()
            return START_NOT_STICKY
        }
        startForegroundCompat()
        if (engine == null) startEngine()
        // START_STICKY: if the OS kills us under memory pressure, restart the
        // service (without the original intent) and re-create the engine.
        return START_STICKY
    }

    private fun startEngine() {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)

        val eng = FlutterEngine(applicationContext)
        val entrypoint = DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(),
            ENTRYPOINT,
        )
        // Plugins (shared_preferences, flutter_secure_storage, path_provider,
        // bonsoir) are registered Dart-side by `DartPluginRegistrant.ensureInitialized()`
        // inside the entry point — see mesh_engine_main.dart.
        eng.dartExecutor.executeDartEntrypoint(entrypoint)
        // BLE channels registered ON the mesh engine, so native BLE events reach the
        // Dart BleConnector directly (no isolate bridge).
        bleController = BleController(applicationContext, eng.dartExecutor.binaryMessenger)
        engine = eng
    }

    private fun stopGracefully() {
        val eng = engine
        if (eng == null || tearingDown) {
            finishTeardown()
            return
        }
        tearingDown = true
        // Ask Dart to tear down (stop bonsoir, close sockets, close Isar) before we
        // destroy the engine, mirroring the old graceful-shutdown path.
        MethodChannel(eng.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .invokeMethod(
                "shutdown",
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) = finishTeardown()
                    override fun error(code: String, msg: String?, details: Any?) =
                        finishTeardown()
                    override fun notImplemented() = finishTeardown()
                },
            )
    }

    private fun finishTeardown() {
        bleController?.dispose()
        bleController = null
        engine?.destroy()
        engine = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        bleController?.dispose()
        bleController = null
        engine?.destroy()
        engine = null
        super.onDestroy()
    }

    private fun startForegroundCompat() {
        ensureChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("UNIUN mesh active")
            .setContentText("Syncing with nearby devices")
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java)
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Offline mesh",
            NotificationManager.IMPORTANCE_LOW,
        ).apply { description = "Keeps the nearby-device mesh running" }
        mgr.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_STOP = "in.uniun.app.mesh.STOP"
        private const val ENTRYPOINT = "meshEngineMain"
        private const val ENGINE_CHANNEL = "in.uniun.app/mesh_engine"
        private const val CHANNEL_ID = "uniun_mesh"
        private const val NOTIFICATION_ID = 7321
    }
}
