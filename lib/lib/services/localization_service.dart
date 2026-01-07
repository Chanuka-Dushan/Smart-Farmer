import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LocalizationService extends ChangeNotifier {
  String _currentLanguage = 'en';
  Map<String, String> _translations = {};

  String get currentLanguage => _currentLanguage;
  Map<String, String> get translations => _translations;

  LocalizationService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? 'en';
    _translations = AppTranslations.getTranslations(_currentLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    _translations = AppTranslations.getTranslations(languageCode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    
    notifyListeners();
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  // Quick access method
  String t(String key) => translate(key);
}

// Extension to make translations easier to use
extension TranslationExtension on BuildContext {
  String tr(String key) {
    return AppTranslations.translate(key, 'en'); // Default to English for stateless access
  }
}
