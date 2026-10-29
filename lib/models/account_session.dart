// One row of GET /api/auth/me/sessions. `ref` identifies the session for a
// single sign-out (the token itself is never returned); `current` marks the
// session this app is using.
class AccountSession {
  final String ref;
  final bool current;
  final String? model;
  final String? os;
  final String? osVersion;
  final String? appVersion;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const AccountSession({
    required this.ref,
    required this.current,
    this.model,
    this.os,
    this.osVersion,
    this.appVersion,
    this.createdAt,
    this.lastSeenAt,
  });

  factory AccountSession.fromJson(Map<String, dynamic> j) {
    final info = j['info'] is Map ? j['info'] as Map<String, dynamic> : const <String, dynamic>{};
    return AccountSession(
      ref: j['ref'] as String,
      current: j['current'] == true,
      model: info['model'] as String?,
      os: info['os'] as String?,
      osVersion: info['osVersion'] as String?,
      appVersion: j['appVersion'] as String?,
      createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal(),
      lastSeenAt: DateTime.tryParse('${j['lastSeenAt']}')?.toLocal(),
    );
  }
}
