import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordAuth {
  String? _password;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _password = prefs.getString('connection_password');
  }

  bool get hasPassword => _password != null && _password!.isNotEmpty;

  String? get password => _password;

  Future<void> setPassword(String? password) async {
    _password = password;
    final prefs = await SharedPreferences.getInstance();
    if (password != null && password.isNotEmpty) {
      await prefs.setString('connection_password', password);
    } else {
      await prefs.remove('connection_password');
    }
  }

  String generateChallenge() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  String hashPassword(String password, String challenge) {
    final bytes = utf8.encode(password + challenge);
    return sha256.convert(bytes).toString();
  }

  bool verify(String challenge, String hash) {
    if (!hasPassword) return true;
    if (_password == null) return true;
    return hashPassword(_password!, challenge) == hash;
  }
}
