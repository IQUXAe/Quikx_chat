import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mymemory_translate/mymemory_translate.dart' as mymemory;
import '../config/setting_keys.dart';

enum TranslationProvider {
  disabled('Disabled'),
  myMemory('MyMemory'),
  googleTranslate('Google Translate'),
  libreTranslate('LibreTranslate');

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
    final prefs = await SharedPreferences.getInstance();
    
    switch (provider) {
      case TranslationProvider.disabled:
        return true;
      case TranslationProvider.myMemory:
        return true; // Always available
      case TranslationProvider.googleTranslate:
        final apiKey = prefs.getString(SettingKeys.googleTranslateApiKey);
        return apiKey != null && apiKey.isNotEmpty;
      case TranslationProvider.libreTranslate:
        final endpoint = prefs.getString(SettingKeys.libreTranslateEndpoint);
        return endpoint != null && endpoint.isNotEmpty;
    }
  }

  static Future<String?> translateText(String text, String fromLang, String toLang) async {
    final provider = await getCurrentProvider();
    
    if (provider == TranslationProvider.disabled) {
      return null;
    }
    
    final isConfigured = await isProviderConfigured(provider);
    
    if (!isConfigured) {
      throw Exception('${provider.displayName} is not configured');
    }

    switch (provider) {
      case TranslationProvider.disabled:
        return null;
      case TranslationProvider.myMemory:
        return await _translateWithMyMemory(text, fromLang, toLang);
      case TranslationProvider.googleTranslate:
        return await _translateWithGoogle(text, fromLang, toLang);
      case TranslationProvider.libreTranslate:
        return await _translateWithLibreTranslate(text, fromLang, toLang);
    }
  }

  static Future<String?> _translateWithMyMemory(String text, String fromLang, String toLang) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(SettingKeys.myMemoryEmail);
    final apiKey = prefs.getString(SettingKeys.myMemoryApiKey);

    try {
      final translator = mymemory.MyMemoryTranslate(http.Client());
      if (email != null && email.isNotEmpty) {
        translator.email = email;
      }
      if (apiKey != null && apiKey.isNotEmpty) {
        translator.key = apiKey;
      }

      // Convert language codes for MyMemory
      final fromCode = _convertToMyMemoryLang(fromLang);
      final toCode = _convertToMyMemoryLang(toLang);

      final result = await translator.translate(text, fromCode, toCode);
      final translatedText = result.responseData.translatedText?.toString();
      
      if (translatedText == null || translatedText.isEmpty || translatedText == text) {
        return null;
      }
      
      return translatedText;
    } catch (e) {
      Logs().w('[MyMemory] Translation failed: $e');
      return null;
    }
  }

  static Future<String?> _translateWithGoogle(String text, String fromLang, String toLang) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(SettingKeys.googleTranslateApiKey);
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Translate API key not configured');
    }

    final url = 'https://translation.googleapis.com/language/translate/v2?key=$apiKey';
    
    final body = {
      'q': text,
      'source': fromLang == 'auto' ? null : fromLang,
      'target': toLang,
      'format': 'text',
    };
    
    body.removeWhere((key, value) => value == null);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['data']?['translations'] as List?;
        
        if (translations != null && translations.isNotEmpty) {
          return translations[0]['translatedText'] as String?;
        }
      }
    } catch (e) {
      Logs().w('[Google] Translation failed: $e');
    }
    return null;
  }

  static Future<String?> _translateWithLibreTranslate(String text, String fromLang, String toLang) async {
    final prefs = await SharedPreferences.getInstance();
    final endpoint = prefs.getString(SettingKeys.libreTranslateEndpoint) ?? 'https://libretranslate.com';
    final apiKey = prefs.getString(SettingKeys.libreTranslateApiKey);

    final url = '$endpoint/translate';
    
    final body = {
      'q': text,
      'source': fromLang == 'auto' ? 'auto' : fromLang,
      'target': toLang,
      'format': 'text',
    };

    if (apiKey != null && apiKey.isNotEmpty) {
      body['api_key'] = apiKey;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['translatedText'] as String?;
      }
    } catch (e) {
      Logs().w('[LibreTranslate] Translation failed: $e');
    }
    return null;
  }

  static String _convertToMyMemoryLang(String lang) {
    // MyMemory использует стандартные языковые коды
    return lang == 'auto' ? 'auto' : lang;
  }

  static Map<String, String> getLanguagesForProvider(TranslationProvider provider) {
    switch (provider) {
      case TranslationProvider.disabled:
        return {};
      case TranslationProvider.myMemory:
        return _getMyMemoryLanguages();
      case TranslationProvider.googleTranslate:
        return _getGoogleLanguages();
      case TranslationProvider.libreTranslate:
        return _getLibreTranslateLanguages();
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

  static Map<String, String> _getGoogleLanguages() {
    return {
      'auto': 'Auto-detect',
      'af': 'Afrikaans',
      'sq': 'Albanian',
      'am': 'Amharic',
      'ar': 'Arabic',
      'hy': 'Armenian',
      'az': 'Azerbaijani',
      'eu': 'Basque',
      'be': 'Belarusian',
      'bn': 'Bengali',
      'bs': 'Bosnian',
      'bg': 'Bulgarian',
      'ca': 'Catalan',
      'ceb': 'Cebuano',
      'ny': 'Chichewa',
      'zh': 'Chinese',
      'co': 'Corsican',
      'hr': 'Croatian',
      'cs': 'Czech',
      'da': 'Danish',
      'nl': 'Dutch',
      'en': 'English',
      'eo': 'Esperanto',
      'et': 'Estonian',
      'tl': 'Filipino',
      'fi': 'Finnish',
      'fr': 'French',
      'fy': 'Frisian',
      'gl': 'Galician',
      'ka': 'Georgian',
      'de': 'German',
      'el': 'Greek',
      'gu': 'Gujarati',
      'ht': 'Haitian Creole',
      'ha': 'Hausa',
      'haw': 'Hawaiian',
      'he': 'Hebrew',
      'hi': 'Hindi',
      'hmn': 'Hmong',
      'hu': 'Hungarian',
      'is': 'Icelandic',
      'ig': 'Igbo',
      'id': 'Indonesian',
      'ga': 'Irish',
      'it': 'Italian',
      'ja': 'Japanese',
      'jw': 'Javanese',
      'kn': 'Kannada',
      'kk': 'Kazakh',
      'km': 'Khmer',
      'ko': 'Korean',
      'ku': 'Kurdish',
      'ky': 'Kyrgyz',
      'lo': 'Lao',
      'la': 'Latin',
      'lv': 'Latvian',
      'lt': 'Lithuanian',
      'lb': 'Luxembourgish',
      'mk': 'Macedonian',
      'mg': 'Malagasy',
      'ms': 'Malay',
      'ml': 'Malayalam',
      'mt': 'Maltese',
      'mi': 'Maori',
      'mr': 'Marathi',
      'mn': 'Mongolian',
      'my': 'Myanmar',
      'ne': 'Nepali',
      'no': 'Norwegian',
      'ps': 'Pashto',
      'fa': 'Persian',
      'pl': 'Polish',
      'pt': 'Portuguese',
      'pa': 'Punjabi',
      'ro': 'Romanian',
      'ru': 'Russian',
      'sm': 'Samoan',
      'gd': 'Scots Gaelic',
      'sr': 'Serbian',
      'st': 'Sesotho',
      'sn': 'Shona',
      'sd': 'Sindhi',
      'si': 'Sinhala',
      'sk': 'Slovak',
      'sl': 'Slovenian',
      'so': 'Somali',
      'es': 'Spanish',
      'su': 'Sundanese',
      'sw': 'Swahili',
      'sv': 'Swedish',
      'tg': 'Tajik',
      'ta': 'Tamil',
      'te': 'Telugu',
      'th': 'Thai',
      'tr': 'Turkish',
      'uk': 'Ukrainian',
      'ur': 'Urdu',
      'uz': 'Uzbek',
      'vi': 'Vietnamese',
      'cy': 'Welsh',
      'xh': 'Xhosa',
      'yi': 'Yiddish',
      'yo': 'Yoruba',
      'zu': 'Zulu',
    };
  }

  static Map<String, String> _getLibreTranslateLanguages() {
    return {
      'auto': 'Auto-detect',
      'ar': 'العربية (Arabic)',
      'az': 'Azərbaycan (Azerbaijani)',
      'bg': 'Български (Bulgarian)',
      'bn': 'বাংলা (Bengali)',
      'ca': 'Català (Catalan)',
      'cs': 'Čeština (Czech)',
      'da': 'Dansk (Danish)',
      'de': 'Deutsch (German)',
      'el': 'Ελληνικά (Greek)',
      'en': 'English',
      'eo': 'Esperanto',
      'es': 'Español (Spanish)',
      'et': 'Eesti (Estonian)',
      'fa': 'فارسی (Persian)',
      'fi': 'Suomi (Finnish)',
      'fr': 'Français (French)',
      'ga': 'Gaeilge (Irish)',
      'he': 'עברית (Hebrew)',
      'hi': 'हिन्दी (Hindi)',
      'hu': 'Magyar (Hungarian)',
      'id': 'Bahasa Indonesia (Indonesian)',
      'it': 'Italiano (Italian)',
      'ja': '日本語 (Japanese)',
      'ko': '한국어 (Korean)',
      'lt': 'Lietuvių (Lithuanian)',
      'lv': 'Latviešu (Latvian)',
      'ms': 'Bahasa Melayu (Malay)',
      'nb': 'Norsk Bokmål (Norwegian)',
      'nl': 'Nederlands (Dutch)',
      'pl': 'Polski (Polish)',
      'pt': 'Português (Portuguese)',
      'ro': 'Română (Romanian)',
      'ru': 'Русский (Russian)',
      'sk': 'Slovenčina (Slovak)',
      'sl': 'Slovenščina (Slovenian)',
      'sq': 'Shqip (Albanian)',
      'sv': 'Svenska (Swedish)',
      'th': 'ไทย (Thai)',
      'tr': 'Türkçe (Turkish)',
      'uk': 'Українська (Ukrainian)',
      'vi': 'Tiếng Việt (Vietnamese)',
      'zh': '中文 (Chinese)',
    };
  }
}