import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../services/api_client.dart';
import '../services/local_prefs.dart';

class AuthState extends ChangeNotifier {
  String? token;
  int? employeeId;
  int? organizationId;
  List<Branch> stores = []; // employee's accessible branches, from login
  int? storeId; // set only after POST /api/pos/auth/store
  Set<String> permissions = {};

  bool get isLoggedIn => token != null;
  bool get hasSelectedStore => storeId != null;
  bool hasPermission(String p) => permissions.contains(p);

  Future<void> login(ApiClient api, String username, String pin) async {
    final session = await api.login(username, pin);
    token = session.token;
    employeeId = session.employeeId;
    organizationId = session.organizationId;
    stores = session.stores;
    storeId = null;
    permissions = {};
    await LocalPrefs.setSession(session.token, username, pin);
    notifyListeners();
  }

  // Explicit store selection — the backend never guesses this (see
  // to_Frontend_AI_On_Inventory_Task [4]). Throws on a store the employee
  // doesn't actually have access to (403).
  Future<void> selectStore(ApiClient api, int chosenStoreId) async {
    final selection = await api.selectStore(token!, chosenStoreId);
    storeId = selection.storeId;
    permissions = selection.permissions;
    await LocalPrefs.setLastStoreId(chosenStoreId);
    notifyListeners();
  }

  // No employee-session equivalent of GET /api/auth/me exists yet (see
  // KioskAuthController precedent — device sessions re-login on every
  // launch rather than validating a cached token). Mirrors that here.
  // Re-selects the last-used store automatically if it's still in the
  // employee's accessible list; otherwise the caller must show the picker.
  Future<bool> resolveStartupAuth(ApiClient api) async {
    final username = await LocalPrefs.username;
    final pin = await LocalPrefs.pin;
    if (username == null || pin == null) return false;
    try {
      await login(api, username, pin);
    } catch (_) {
      await LocalPrefs.clear();
      return false;
    }
    final lastStoreId = await LocalPrefs.lastStoreId;
    if (lastStoreId != null && stores.any((b) => b.id == lastStoreId)) {
      try {
        await selectStore(api, lastStoreId);
      } catch (_) {
        // Access revoked since last launch — leave storeId null, caller shows the picker.
      }
    }
    return true;
  }

  // Undoes a store selection without logging out — used when the chosen
  // store turns out to grant no inventory permission, so the employee can
  // pick a different branch on the same account (see StoreSelectScreen's
  // "Back to Stores" recovery).
  void clearStoreSelection() {
    storeId = null;
    permissions = {};
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    employeeId = null;
    organizationId = null;
    stores = [];
    storeId = null;
    permissions = {};
    await LocalPrefs.clear();
    notifyListeners();
  }
}
