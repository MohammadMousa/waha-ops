import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/local_prefs.dart';

class AuthState extends ChangeNotifier {
  String? token;
  int? employeeId;
  int? organizationId;
  int? storeId; // employee's fixed origin/home store
  Set<String> permissions = {};

  bool get isLoggedIn => token != null;
  bool hasPermission(String p) => permissions.contains(p);

  Future<void> login(ApiClient api, String username, String pin) async {
    final session = await api.login(username, pin);
    token = session.token;
    employeeId = session.employeeId;
    organizationId = session.organizationId;
    storeId = session.storeId;
    permissions = session.permissions;
    await LocalPrefs.setSession(session.token, username, pin);
    notifyListeners();
  }

  // No employee-session equivalent of GET /api/auth/me exists yet (see
  // KioskAuthController precedent — device sessions re-login on every
  // launch rather than validating a cached token). Mirrors that here.
  Future<bool> resolveStartupAuth(ApiClient api) async {
    final username = await LocalPrefs.username;
    final pin = await LocalPrefs.pin;
    if (username == null || pin == null) return false;
    try {
      await login(api, username, pin);
      return true;
    } catch (_) {
      await LocalPrefs.clear();
      return false;
    }
  }

  Future<void> logout() async {
    token = null;
    employeeId = null;
    organizationId = null;
    storeId = null;
    permissions = {};
    await LocalPrefs.clear();
    notifyListeners();
  }
}
