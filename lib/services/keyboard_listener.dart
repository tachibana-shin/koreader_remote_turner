import 'package:flutter/services.dart';
import 'package:kaeru/kaeru.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum KeyAction { forward, backward, sleep }

class KnownKeys {
  static const Map<String, LogicalKeyboardKey?> all = {
    'None': null,
    'Audio Volume Up': LogicalKeyboardKey.audioVolumeUp,
    'Audio Volume Down': LogicalKeyboardKey.audioVolumeDown,
    'Audio Volume Mute': LogicalKeyboardKey.audioVolumeMute,
    'Enter': LogicalKeyboardKey.enter,
    'Space': LogicalKeyboardKey.space,
    'Escape': LogicalKeyboardKey.escape,
    'Tab': LogicalKeyboardKey.tab,
    'Arrow Up': LogicalKeyboardKey.arrowUp,
    'Arrow Down': LogicalKeyboardKey.arrowDown,
    'Arrow Left': LogicalKeyboardKey.arrowLeft,
    'Arrow Right': LogicalKeyboardKey.arrowRight,
    'Page Up': LogicalKeyboardKey.pageUp,
    'Page Down': LogicalKeyboardKey.pageDown,
    'Home': LogicalKeyboardKey.home,
    'End': LogicalKeyboardKey.end,
    'Backspace': LogicalKeyboardKey.backspace,
    'Delete': LogicalKeyboardKey.delete,
    'Insert': LogicalKeyboardKey.insert,
    'F1': LogicalKeyboardKey.f1,
    'F2': LogicalKeyboardKey.f2,
    'F3': LogicalKeyboardKey.f3,
    'F4': LogicalKeyboardKey.f4,
    'F5': LogicalKeyboardKey.f5,
    'F6': LogicalKeyboardKey.f6,
    'F7': LogicalKeyboardKey.f7,
    'F8': LogicalKeyboardKey.f8,
    'F9': LogicalKeyboardKey.f9,
    'F10': LogicalKeyboardKey.f10,
    'F11': LogicalKeyboardKey.f11,
    'F12': LogicalKeyboardKey.f12,
    'Digit 0': LogicalKeyboardKey.digit0,
    'Digit 1': LogicalKeyboardKey.digit1,
    'Digit 2': LogicalKeyboardKey.digit2,
    'Digit 3': LogicalKeyboardKey.digit3,
    'Digit 4': LogicalKeyboardKey.digit4,
    'Digit 5': LogicalKeyboardKey.digit5,
    'Digit 6': LogicalKeyboardKey.digit6,
    'Digit 7': LogicalKeyboardKey.digit7,
    'Digit 8': LogicalKeyboardKey.digit8,
    'Digit 9': LogicalKeyboardKey.digit9,
    'Key A': LogicalKeyboardKey.keyA,
    'Key B': LogicalKeyboardKey.keyB,
    'Key C': LogicalKeyboardKey.keyC,
    'Key D': LogicalKeyboardKey.keyD,
    'Key E': LogicalKeyboardKey.keyE,
    'Key F': LogicalKeyboardKey.keyF,
    'Key G': LogicalKeyboardKey.keyG,
    'Key H': LogicalKeyboardKey.keyH,
    'Key I': LogicalKeyboardKey.keyI,
    'Key J': LogicalKeyboardKey.keyJ,
    'Key K': LogicalKeyboardKey.keyK,
    'Key L': LogicalKeyboardKey.keyL,
    'Key M': LogicalKeyboardKey.keyM,
    'Key N': LogicalKeyboardKey.keyN,
    'Key O': LogicalKeyboardKey.keyO,
    'Key P': LogicalKeyboardKey.keyP,
    'Key Q': LogicalKeyboardKey.keyQ,
    'Key R': LogicalKeyboardKey.keyR,
    'Key S': LogicalKeyboardKey.keyS,
    'Key T': LogicalKeyboardKey.keyT,
    'Key U': LogicalKeyboardKey.keyU,
    'Key V': LogicalKeyboardKey.keyV,
    'Key W': LogicalKeyboardKey.keyW,
    'Key X': LogicalKeyboardKey.keyX,
    'Key Y': LogicalKeyboardKey.keyY,
    'Key Z': LogicalKeyboardKey.keyZ,
    'Media Play Pause': LogicalKeyboardKey.mediaPlayPause,
    'Media Track Next': LogicalKeyboardKey.mediaTrackNext,
    'Media Track Previous': LogicalKeyboardKey.mediaTrackPrevious,
    'Media Stop': LogicalKeyboardKey.mediaStop,
  };

  static String nameOf(LogicalKeyboardKey key) {
    for (final e in all.entries) {
      if (e.value == key) return e.key;
    }
    return 'None';
  }
}

class ButtonConfig {
  final List<LogicalKeyboardKey> forwardKeys;
  final List<LogicalKeyboardKey> backwardKeys;
  final List<LogicalKeyboardKey> sleepKeys;
  final bool onlyWhileOpen;

  ButtonConfig({
    this.forwardKeys = const [
      LogicalKeyboardKey.audioVolumeUp,
      LogicalKeyboardKey.arrowRight,
    ],
    this.backwardKeys = const [
      LogicalKeyboardKey.audioVolumeDown,
      LogicalKeyboardKey.arrowLeft,
    ],
    this.sleepKeys = const [LogicalKeyboardKey.audioVolumeMute],
    this.onlyWhileOpen = true,
  });
}

class KeyboardListenerService {
  final actionRef = Ref<KeyAction?>(null);
  ButtonConfig _config = ButtonConfig();
  bool _listening = false;

  ButtonConfig get config => _config;

  void emit(KeyAction action) {
    if (_listening) actionRef.value = action;
  }

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _config = ButtonConfig(
      forwardKeys: _parseKeyList(
        prefs.getString('key_forward') ?? 'Audio Volume Up,Arrow Right',
      ),
      backwardKeys: _parseKeyList(
        prefs.getString('key_backward') ?? 'Audio Volume Down,Arrow Left',
      ),
      sleepKeys: _parseKeyList(
        prefs.getString('key_sleep') ?? 'Audio Volume Mute',
      ),
      onlyWhileOpen: prefs.getBool('only_while_open') ?? true,
    );
  }

  Future<void> saveConfig(ButtonConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'key_forward',
      config.forwardKeys.map(KnownKeys.nameOf).join(','),
    );
    await prefs.setString(
      'key_backward',
      config.backwardKeys.map(KnownKeys.nameOf).join(','),
    );
    await prefs.setString(
      'key_sleep',
      config.sleepKeys.map(KnownKeys.nameOf).join(','),
    );
    await prefs.setBool('only_while_open', config.onlyWhileOpen);
  }

  KeyAction? handleKeyEvent(KeyEvent event) {
    if (!_listening) return null;
    if (event is! KeyDownEvent) return null;
    return actionForKey(event.logicalKey);
  }

  KeyAction? actionForKey(LogicalKeyboardKey key) {
    if (_config.forwardKeys.contains(key)) return KeyAction.forward;
    if (_config.backwardKeys.contains(key)) return KeyAction.backward;
    if (_config.sleepKeys.contains(key)) return KeyAction.sleep;
    return null;
  }

  void startListening() {
    _listening = true;
  }

  void stopListening() {
    _listening = false;
  }

  static List<LogicalKeyboardKey> _parseKeyList(String value) {
    return value.split(',').map((s) {
      final key = KnownKeys.all[s.trim()];
      return key ?? LogicalKeyboardKey.audioVolumeUp;
    }).toList();
  }
}
