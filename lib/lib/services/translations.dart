import '../translations/translate_en.dart';
import '../translations/translate_si.dart';
import '../translations/translate_ta.dart';

class AppTranslations {
  static final Map<String, Map<String, String>> _translations = _buildTranslations();

  static Map<String, Map<String, String>> _buildTranslations() {
    final Map<String, Map<String, String>> translations = {};
    
    // Iterate through all keys from English translations (master list)
    for (var key in TranslateEN.labels.keys) {
      translations[key] = {
        'en': TranslateEN.labels[key] ?? '',
        'si': TranslateSI.labels[key] ?? '',
        'ta': TranslateTA.labels[key] ?? '',
      };
    }
    
    return translations;
  }
  
  static String translate(String key, String languageCode) {
    return _translations[key]?[languageCode] ?? _translations[key]?['en'] ?? key;
  }

  static Map<String, String> getTranslations(String languageCode) {
    Map<String, String> result = {};
    _translations.forEach((key, value) {
      result[key] = value[languageCode] ?? value['en'] ?? key;
    });
    return result;
  }
}
