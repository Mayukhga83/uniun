import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// The BLE byte pipe, registered on the MAIN engine. The mesh runs inline on the
  /// main isolate (no second `FlutterEngine` — `package:objective_c` breaks with
  /// multiple engines). Idle until Dart invokes `start`. Implementation lives in the
  /// shared UniunBleMesh.swift (../../ios/Runner/UniunBleMesh.swift), compiled into
  /// both the iOS and macOS targets via a conditional Flutter/FlutterMacOS import.
  private var bleMesh: UniunBleMesh?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    bleMesh = UniunBleMesh(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
