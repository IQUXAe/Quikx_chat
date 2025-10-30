import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/setting_keys.dart';

enum TranslationProvider {
  disabled('Disabled'),
  myMemory('MyMemory');

  const TranslationProvider(this.displayName);
  final String displayName;
}

class TranslationProviders {
  static Future<TranslationProvider> getCurrentProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString(SettingKeys.translationProvider) ?? 'myMemory';
    return TranslationProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => TranslationProvider.myMemory,
    );
  }

  static Future<void> setProvider(TranslationProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingKeys.translationProvider, provider.name);
  }

  static Future<bool> isProviderConfigured(TranslationProvider provider) async {
    switch (provider) {
      case TranslationProvider.disabled:
        return false;
      case TranslationProvider.myMemory:
        return true;
    }
  }

  static Future<String?> translateText(String text, String fromLang, String toLang) async {
    final provider = await getCurrentProvider();
    
    if (provider == TranslationProvider.disabled) {
      return null;
    }
    
    return await _translateWithMyMemory(text, fromLang, toLang);
  }

  static Future<String?> _translateWithMyMemory(String text, String fromLang, String toLang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SettingKeys.myMemoryEmail);
      final apiKey = prefs.getString(SettingKeys.myMemoryApiKey);

      final fromCode = _convertToMyMemoryLang(fromLang);
      final toCode = _convertToMyMemoryLang(toLang);
      
      final uri = Uri.parse('https://api.mymemory.translated.net/get').replace(
        queryParameters: {
          'q': text,
          'langpair': '$fromCode|$toCode',
          if (email != null && email.isNotEmpty) 'de': email,
          if (apiKey != null && apiKey.isNotEmpty) 'key': apiKey,
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      
      final data = json.decode(response.body);
      final translatedText = data['responseData']?['translatedText']?.toString();
      
      if (translatedText == null || translatedText.isEmpty || translatedText == text) {
        return null;
      }
      
      return translatedText;
    } catch (e) {
      Logs().w('[MyMemory] Translation failed: $e');
      return null;
    }
  }

  static String _convertToMyMemoryLang(String lang) {
    return lang == 'auto' ? 'auto' : lang;
  }

  static Map<String, String> getLanguagesForProvider(TranslationProvider provider) {
    switch (provider) {
      case TranslationProvider.disabled:
        return {};
      case TranslationProvider.myMemory:
        return _getMyMemoryLanguages();
    }
  }

  static Map<String, String> _getMyMemoryLanguages() {
    return {
      'auto': 'Auto-detect',
      'af': 'Afrikaans',
      'sq': 'Albanian',
      'am': 'Amharic',
      'ar': 'العربية',
      'hy': 'Armenian',
      'az': 'Azerbaijani',
      'eu': 'Basque',
      'be': 'Belarusian',
      'bn': 'বাংলা',
      'bs': 'Bosnian',
      'bg': 'Български',
      'ca': 'Català',
      'ceb': 'Cebuano',
      'ny': 'Chichewa',
      'zh': '中文',
      'co': 'Corsican',
      'hr': 'Hrvatski',
      'cs': 'Čeština',
      'da': 'Dansk',
      'nl': 'Nederlands',
      'en': 'English',
      'eo': 'Esperanto',
      'et': 'Eesti',
      'tl': 'Filipino',
      'fi': 'Suomi',
      'fr': 'Français',
      'fy': 'Frisian',
      'gl': 'Galician',
      'ka': 'Georgian',
      'de': 'Deutsch',
      'el': 'Ελληνικά',
      'gu': 'ગુજરાતી',
      'ht': 'Haitian Creole',
      'ha': 'Hausa',
      'haw': 'Hawaiian',
      'he': 'עברית',
      'hi': 'हिन्दी',
      'hmn': 'Hmong',
      'hu': 'Magyar',
      'is': 'Icelandic',
      'ig': 'Igbo',
      'id': 'Bahasa Indonesia',
      'ga': 'Irish',
      'it': 'Italiano',
      'ja': '日本語',
      'jw': 'Javanese',
      'kn': 'ಕನ್ನಡ',
      'kk': 'Kazakh',
      'km': 'Khmer',
      'ko': '한국어',
      'ku': 'Kurdish',
      'ky': 'Kyrgyz',
      'lo': 'Lao',
      'la': 'Latin',
      'lv': 'Latviešu',
      'lt': 'Lietuvių',
      'lb': 'Luxembourgish',
      'mk': 'Macedonian',
      'mg': 'Malagasy',
      'ms': 'Bahasa Melayu',
      'ml': 'Malayalam',
      'mt': 'Maltese',
      'mi': 'Maori',
      'mr': 'Marathi',
      'mn': 'Mongolian',
      'my': 'Myanmar',
      'ne': 'Nepali',
      'no': 'Norsk',
      'ps': 'Pashto',
      'fa': 'فارسی',
      'pl': 'Polski',
      'pt': 'Português',
      'pa': 'ਪੰਜਾਬੀ',
      'ro': 'Română',
      'ru': 'Русский',
      'sm': 'Samoan',
      'gd': 'Scots Gaelic',
      'sr': 'Serbian',
      'st': 'Sesotho',
      'sn': 'Shona',
      'sd': 'Sindhi',
      'si': 'Sinhala',
      'sk': 'Slovenčina',
      'sl': 'Slovenščina',
      'so': 'Somali',
      'es': 'Español',
      'su': 'Sundanese',
      'sw': 'Swahili',
      'sv': 'Svenska',
      'tg': 'Tajik',
      'ta': 'தமிழ்',
      'te': 'తెలుగు',
      'th': 'ไทย',
      'tr': 'Türkçe',
      'uk': 'Українська',
      'ur': 'اردو',
      'uz': 'Uzbek',
      'vi': 'Tiếng Việt',
      'cy': 'Welsh',
      'xh': 'Xhosa',
      'yi': 'Yiddish',
      'yo': 'Yoruba',
      'zu': 'Zulu',
    };
  }


}