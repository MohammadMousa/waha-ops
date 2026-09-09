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

  String? title(String languageCode) =>
      _appName?[languageCode] as String? ?? _appName?['en'] as String?;

  Future<void> load(ApiClient api) async {
    try {
      final appName = await api.getAppName();
      if (appName != null) {
        _appName = appName;
        notifyListeners();
      }
    } catch (_) {
      // Callers fall back to the hardcoded l10n appTitle string.
    }
  }
}
