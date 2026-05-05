import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

// Language service with ChangeNotifier for reactive language switching
class L10n extends ChangeNotifier {
  static final L10n _instance = L10n._internal();
  factory L10n() => _instance;
  L10n._internal();

  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  // Initialize language from SharedPreferences
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? 'en';
    notifyListeners();
  }

  // Get translation for a key
  String tr(String key) {
    return AppTranslations.translate(key, _currentLanguage);
  }

  // Change language and persist
  Future<void> setLanguage(String code) async {
    if (_currentLanguage != code) {
      _currentLanguage = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', code);
      notifyListeners(); // This triggers UI rebuild
    }
  }

  // Static helper for backward compatibility
  static String translate(String key) {
    return _instance.tr(key);
  }
}
