package `in`.uniun.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // UI → native mesh lifecycle. `start` spins up the headless mesh engine via
        // the foreground service; `stop` asks it to tear down gracefully.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MESH_CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        // Request the runtime permissions the mesh needs (BLE +,
                        // on Android 13+, notifications). Non-blocking: the service
                        // still starts; BLE simply stays idle until granted.
                        ensureMeshPermissions()
                        ContextCompat.startForegroundService(
                            this,
                            Intent(this, MeshForegroundService::class.java),
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        startService(
                            Intent(this, MeshForegroundService::class.java)
                                .apply { action = MeshForegroundService.ACTION_STOP },
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureMeshPermissions() {
        val wanted = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            wanted += Manifest.permission.BLUETOOTH_SCAN
            wanted += Manifest.permission.BLUETOOTH_CONNECT
            wanted += Manifest.permission.BLUETOOTH_ADVERTISE
        } else {
            wanted += Manifest.permission.ACCESS_FINE_LOCATION
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            wanted += Manifest.permission.POST_NOTIFICATIONS
        }
        val missing = wanted.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQ_MESH_PERMS)
        }
    }

    companion object {
        private const val MESH_CONTROL_CHANNEL = "in.uniun.app/mesh_control"
        private const val REQ_MESH_PERMS = 9201
    }
}
