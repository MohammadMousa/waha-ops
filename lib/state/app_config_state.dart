import 'package:flutter/material.dart';

import '../services/api_client.dart';

// The app/org display name comes from the server now, not a hardcoded
// string — per to_Frontend_AI_On_Inventory_Task [11]: `GET /api/config`
// (no auth, callable before login) returns `appName: {ar, en}`. Fetched
// once at app start; `title()` is watched wherever the name is shown so it
// re-renders on a language toggle too. The hardcoded l10n `appTitle`
// string is a fallback ONLY — used while this hasn't loaded yet, or if the
// call fails (offline first launch, endpoint not deployed yet, etc.).
class AppConfigState extends ChangeNotifier {
  Map<String, dynamic>? _appName;

  int _apiLevel = 0;

  // Backend feature level from GET /api/config; 0 until loaded or when the
  // backend predates the field. Account sessions need 3.
  bool get supportsAccountSessions => _apiLevel >= 3;

  String? title(String languageCode) =>
      _appName?[languageCode] as String? ?? _appName?['en'] as String?;

  Future<void> load(ApiClient api) async {
    try {
      final config = await api.getConfig();
      _apiLevel = int.tryParse('${config['api_level']}') ?? 0;
      _appName = config['appName'] as Map<String, dynamic>?;
      notifyListeners();
    } catch (_) {
      // Callers fall back to the hardcoded l10n appTitle string.
    }
  }
}
