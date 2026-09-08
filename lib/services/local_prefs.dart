import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static const _tokenKey = 'ops_employee_token';
  static const _usernameKey = 'ops_employee_username';
  static const _pinKey = 'ops_employee_pin';

  static Future<void> setSession(String token, String username, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_pinKey, pin);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_pinKey);
  }

  static Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);
  static Future<String?> get username async =>
      (await SharedPreferences.getInstance()).getString(_usernameKey);
  static Future<String?> get pin async =>
      (await SharedPreferences.getInstance()).getString(_pinKey);
}
