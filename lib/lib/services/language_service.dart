import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _languageSelectedKey = 'language_selected';

  // Get current language
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  // Set language
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    await prefs.setBool(_languageSelectedKey, true);
  }

  // Check if language has been selected
  static Future<bool> isLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  // Get language name
  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }

  // Get all available languages
  static List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
      {'code': 'si', 'name': 'Sinhala', 'nativeName': 'සිංහල', 'flag': '🇱🇰'},
      {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇱🇰'},
    ];
  }
}
