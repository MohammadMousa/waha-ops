import 'package:shared_preferences/shared_preferences.dart';

// Stores only the session token — never the PIN. AuthState.resolveStartupAuth
// validates the cached token against GET /api/pos/auth/me instead of
// resending credentials (human lead's auth rule: a stored token alone
// should be enough to auto-login, never a stored password/PIN).
class LocalPrefs {
  static const _tokenKey = 'ops_employee_token';
  static const _lastStoreIdKey = 'ops_last_store_id';

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> setLastStoreId(int storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastStoreIdKey, storeId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_lastStoreIdKey);
  }

  static Future<String?> get token async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);
  static Future<int?> get lastStoreId async =>
      (await SharedPreferences.getInstance()).getInt(_lastStoreIdKey);
}
