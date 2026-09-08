import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'ops_locale';

class LocaleState extends ChangeNotifier {
  Locale locale = const Locale('en');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code == 'ar') {
      locale = const Locale('ar');
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    locale = locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    notifyListeners();
  }
}
