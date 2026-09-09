import 'branch.dart';

// Response shape for POST /api/pos/auth/login (per
// ~/git/to_Frontend_AI_On_Inventory_Task [8], 2026-09-09 — breaking change,
// supersedes [4]). Permissions are resolved once at login and apply
// uniformly across every store the employee can access — there is no
// per-store permission call anymore. `stores` is the employee's own
// accessible branches; the frontend picks one locally (POST
// /api/pos/auth/store no longer exists) and sends that storeId on
// POST /api/inventory/visits.
class EmployeeSession {
  final String token;
  final int employeeId;
  final int organizationId;
  final Set<String> permissions;
  final List<Branch> stores;
  // Added per to_Frontend_AI_On_Inventory_Task [10] (2026-09-09): real
  // name (first+last) and the raw role enum ("BRANCH_ADMIN") — format the
  // latter for display, see AuthState.roleLabel.
  final String? employeeName;
  final String? roleName;

  const EmployeeSession({
    required this.token,
    required this.employeeId,
    required this.organizationId,
    this.permissions = const {},
    this.stores = const [],
    this.employeeName,
    this.roleName,
  });

  factory EmployeeSession.fromJson(Map<String, dynamic> json) {
    final rawStores = json['stores'];
    final stores = rawStores is List
        ? rawStores.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList()
        : const <Branch>[];
    final rawPerms = json['permissions'];
    final permissions =
        rawPerms is List ? rawPerms.map((e) => e.toString()).toSet() : const <String>{};
    return EmployeeSession(
      token: json['token'] as String,
      employeeId: (json['employeeId'] as num).toInt(),
      organizationId: (json['organizationId'] as num).toInt(),
      permissions: permissions,
      stores: stores,
      employeeName: json['employeeName'] as String?,
      roleName: json['roleName'] as String?,
    );
  }
}
