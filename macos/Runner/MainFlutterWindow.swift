import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let methodChannel = FlutterMethodChannel(
      name: "com.example.koreader_remote_turner/service",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    methodChannel.setMethodCallHandler { (_, result) in
      result(FlutterMethodNotImplemented)
    }

    let eventChannel = FlutterEventChannel(
      name: "com.example.koreader_remote_turner/events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    eventChannel.setStreamHandler(VolumeStreamHandler())

    super.awakeFromNib()
  }
}

private class VolumeStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
