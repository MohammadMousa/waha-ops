import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/employee_session.dart';
import '../services/api_client.dart';
import '../services/local_prefs.dart';

class AuthState extends ChangeNotifier {
  String? token;
  int? employeeId;
  int? organizationId;
  // The login username — kept as a fallback identity line for whenever
  // employeeName isn't available (e.g. an older cached session).
  String? username;
  String? employeeName; // real display name, per to_Frontend...[10]
  String? roleName; // raw role enum ("BRANCH_ADMIN") — see roleLabel
  List<Branch> stores = []; // employee's accessible branches, from login
  Set<String> permissions = {}; // resolved once at login, applies to every store
  int? storeId; // chosen locally on this screen — no backend call for this

  bool get isLoggedIn => token != null;
  bool get hasSelectedStore => storeId != null;
  bool hasPermission(String p) => permissions.contains(p);

  // "BRANCH_ADMIN" -> "Branch Admin"
  String? get roleLabel {
    final r = roleName;
    if (r == null || r.isEmpty) return null;
    return r.split('_').map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}').join(' ');
  }

  Future<void> login(ApiClient api, String username, String pin) async {
    final session = await api.login(username, pin);
    _applySession(session, username: username);
    await LocalPrefs.setToken(session.token);
    notifyListeners();
  }

  void _applySession(EmployeeSession session, {String? username}) {
    token = session.token;
    employeeId = session.employeeId;
    organizationId = session.organizationId;
    this.username = username;
    // Blank counts as absent too — some accounts have an empty
    // first/last name on the backend, not just a missing field, and the
    // identity line must never render empty (human lead, 2026-09-09).
    employeeName = (session.employeeName?.trim().isEmpty ?? true) ? null : session.employeeName;
    roleName = session.roleName;
    stores = session.stores;
    permissions = session.permissions;
    storeId = null;
  }

  // Local-only pick — POST /api/pos/auth/store no longer exists (see
  // to_Frontend_AI_On_Inventory_Task [8], 2026-09-09). Permissions are
  // already resolved at login and apply the same regardless of which
  // store gets picked here; this just records which one the employee is
  // working at for this visit.
  void selectStore(int chosenStoreId) {
    storeId = chosenStoreId;
    LocalPrefs.setLastStoreId(chosenStoreId);
    notifyListeners();
  }

  // Validates the cached token against GET /api/pos/auth/me — never resends
  // the PIN, and the PIN itself is never persisted (only the token is).
  //
  // Deliberately does NOT auto-pick a store or resume a visit — a reload
  // must always land back on the store-select screen, never silently
  // jump into a branch + started visit (human lead, 2026-09-08).
  Future<bool> resolveStartupAuth(ApiClient api) async {
    final cachedToken = await LocalPrefs.token;
    if (cachedToken == null) return false;
    try {
      final session = await api.me(cachedToken);
      _applySession(session);
    } catch (_) {
      await LocalPrefs.clear();
      return false;
    }
    return true;
  }

  void clearStoreSelection() {
    storeId = null;
    notifyListeners();
  }

  // Ends the session on the server first so the backend drops it, then clears
  // local state. A failed server call (offline) must not trap the employee in
  // the app, so local sign-out happens regardless.
  Future<void> logout(ApiClient api) async {
    final t = token;
    if (t != null) {
      try {
        await api.logout(t);
      } catch (_) {}
    }
    await clearSession();
  }

  // Local-only sign-out, for when the server already ended the session.
  Future<void> clearSession() async {
    token = null;
    employeeId = null;
    organizationId = null;
    username = null;
    employeeName = null;
    roleName = null;
    stores = [];
    storeId = null;
    permissions = {};
    await LocalPrefs.clear();
    notifyListeners();
  }
}
