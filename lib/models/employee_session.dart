// Response shape for POST /api/pos/auth/login (per
// ~/git/to_Frontend_AI_On_Inventory_Task). storeId is the employee's fixed
// origin/home store — not a list of assignable branches; the destination
// branch for an operation is a separate concept (GET /api/inventory/branches).
class EmployeeSession {
  final String token;
  final int employeeId;
  final int organizationId;
  final int storeId;
  final Set<String> permissions;

  const EmployeeSession({
    required this.token,
    required this.employeeId,
    required this.organizationId,
    required this.storeId,
    this.permissions = const {},
  });

  factory EmployeeSession.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final permissions = rawPerms is List
        ? rawPerms.map((e) => e.toString()).toSet()
        : const <String>{};
    return EmployeeSession(
      token: json['token'] as String,
      employeeId: (json['employeeId'] as num).toInt(),
      organizationId: (json['organizationId'] as num).toInt(),
      storeId: (json['storeId'] as num).toInt(),
      permissions: permissions,
    );
  }
}
