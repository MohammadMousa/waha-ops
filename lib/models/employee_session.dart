import 'branch.dart';

// Response shape for POST /api/pos/auth/login (per
// ~/git/to_Frontend_AI_On_Inventory_Task [4]). No storeId/permissions here
// anymore — the backend never guesses a store. `stores` is the employee's
// own accessible branches; the frontend picks one (or auto-picks the only
// one, or shows "no branches assigned" if empty) and calls
// POST /api/pos/auth/store to get storeId + permissions.
class EmployeeSession {
  final String token;
  final int employeeId;
  final int organizationId;
  final List<Branch> stores;

  const EmployeeSession({
    required this.token,
    required this.employeeId,
    required this.organizationId,
    this.stores = const [],
  });

  factory EmployeeSession.fromJson(Map<String, dynamic> json) {
    final rawStores = json['stores'];
    final stores = rawStores is List
        ? rawStores.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList()
        : const <Branch>[];
    return EmployeeSession(
      token: json['token'] as String,
      employeeId: (json['employeeId'] as num).toInt(),
      organizationId: (json['organizationId'] as num).toInt(),
      stores: stores,
    );
  }
}

// Response shape for POST /api/pos/auth/store.
class StoreSelection {
  final int storeId;
  final Set<String> permissions;
  const StoreSelection({required this.storeId, required this.permissions});

  factory StoreSelection.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final permissions =
        rawPerms is List ? rawPerms.map((e) => e.toString()).toSet() : const <String>{};
    return StoreSelection(storeId: (json['storeId'] as num).toInt(), permissions: permissions);
  }
}
