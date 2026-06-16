import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// The BLE byte pipe, registered on the MAIN engine. On iOS the mesh runs inline
  /// on the main isolate (no second `FlutterEngine` — `package:objective_c` breaks
  /// with multiple engines), so the Dart `BleConnector` reaches BLE through the main
  /// engine's messenger. `UniunBleMesh` is idle until Dart invokes `start`.
  /// Implementation lives in the shared UniunBleMesh.swift (compiled into both the
  /// iOS and macOS targets).
  private var bleMesh: UniunBleMesh?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let messenger = engineBridge.pluginRegistry
      .registrar(forPlugin: "UniunBleMesh")?.messenger() {
      bleMesh = UniunBleMesh(messenger: messenger)
    }
  }
}
