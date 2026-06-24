import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  Future<int> getPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('server_port') ?? 9090;
  }

  Future<void> setPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('server_port', port);
  }

  Future<int?> getTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('server_timeout');
  }

  Future<void> setTimeout(int? minutes) async {
    final prefs = await SharedPreferences.getInstance();
    if (minutes != null) {
      await prefs.setInt('server_timeout', minutes);
    } else {
      await prefs.remove('server_timeout');
    }
  }

  Future<bool> getAutoStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_start') ?? true;
  }

  Future<void> setAutoStart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start', value);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString('theme_mode', value);
  }
}
