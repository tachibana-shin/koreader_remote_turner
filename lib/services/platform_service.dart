import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class PlatformService {
  static const _methodChannel = MethodChannel(
    'git.shin.koreader_remote_turner/service',
  );
  static const _eventChannel = EventChannel(
    'git.shin.koreader_remote_turner/events',
  );

  static final StreamController<String> _volumeEventController =
      StreamController<String>.broadcast();

  static Stream<String> get volumeEvents => _volumeEventController.stream;

  static void init() {
    if (!Platform.isAndroid) return;
    _eventChannel
        .receiveBroadcastStream()
        .map((e) => e.toString())
        .listen(_volumeEventController.add, onError: (_) {});
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'volumeKeyPressed') {
        _volumeEventController.add(call.arguments as String);
      }
    });
  }

  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> startForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('startService');
    } catch (_) {}
  }

  static Future<void> stopForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('stopService');
    } catch (_) {}
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isAccessibilityServiceEnabled',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }
}
