import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var eventSink: FlutterEventSink?
  private var volumeObservation: NSKeyValueObservation?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let messenger = engineBridge.engine?.binaryMessenger else { return }

    let methodChannel = FlutterMethodChannel(
      name: "com.example.koreader_remote_turner/service",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "startService":
        self?.startVolumeMonitoring()
        result(nil)
      case "stopService":
        self?.stopVolumeMonitoring()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "com.example.koreader_remote_turner/events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  private func startVolumeMonitoring() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    } catch {
      print("[RemoteTurner] AudioSession error: \(error)")
      return
    }

    volumeObservation = session.observe(\.outputVolume, options: [.new, .old]) {
      [weak self] _, change in
      guard let new = change.newValue, let old = change.oldValue else { return }
      if new > old {
        self?.eventSink?("volume_up")
      } else if new < old {
        self?.eventSink?("volume_down")
      }
    }
  }

  private func stopVolumeMonitoring() {
    volumeObservation?.invalidate()
    volumeObservation = nil
    try? AVAudioSession.sharedInstance().setActive(false)
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
