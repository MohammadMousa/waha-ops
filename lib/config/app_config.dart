class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  // Waha Ops has no org picker anywhere — login never sends
  // `organizationId` either, and the backend defaults that to 1 when
  // absent (PosAuthController.login()). Mirrored here so GET /api/config
  // (needs orgId to merge org-specific properties, like appName) resolves
  // against the same org login implicitly does.
  static const int defaultOrganizationId = 1;

  // GET /api/resources/{id} — public, unauthenticated, content-addressed
  // (safe to cache forever). Per to_Frontend_AI_On_Inventory_Task [10].
  static String? resourceUrl(int? resourceId) =>
      resourceId == null ? null : '$apiBaseUrl/api/resources/$resourceId';
}
