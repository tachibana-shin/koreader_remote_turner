import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class PlatformService {
  static const _methodChannel = MethodChannel(
    'com.example.koreader_remote_turner/service',
  );
  static const _eventChannel = EventChannel(
    'com.example.koreader_remote_turner/events',
  );

  static Future<void> startForegroundService() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _methodChannel.invokeMethod('startService');
    } catch (_) {}
  }

  static Future<void> stopForegroundService() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _methodChannel.invokeMethod('stopService');
    } catch (_) {}
  }

  static Stream<String> get volumeEvents {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const Stream.empty();
    }
    return _eventChannel.receiveBroadcastStream().map((event) {
      return event.toString();
    }).handleError((_) {});
  }
}
