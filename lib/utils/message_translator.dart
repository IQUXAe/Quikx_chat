import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/chat/events/message.dart';
import '../config/setting_keys.dart';
import 'translation_providers.dart';

class MessageTranslator {
  static const String _cachePrefix = 'translation_cache_';
  static const String _enabledKey = 'translation_enabled';
  static const String _targetLanguageKey = 'translation_target_language';
  static const int _maxConcurrentTranslations = 10;
  static int _activeTranslations = 0;
  static final Set<String> _translatingEvents = <String>{};
  
  static Future<bool> get isEnabled async {
    final provider = await TranslationProviders.getCurrentProvider();
    final isConfigured = await TranslationProviders.isProviderConfigured(provider);
    final prefs = await SharedPreferences.getInstance();
    return isConfigured && (prefs.getBool(_enabledKey) ?? true);
  }
  
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
  
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    // Очищаем также активные переводы в UI
    messageTranslations.clear();
    notifyTranslationChanged();
    Logs().i('[MessageTranslator] Cache and active translations cleared');
  }

  static Future<String?> translateMessage(String text, String targetLang) async {
    Logs().i('[Translator] Starting translation for: "$text"');
    
    final cleanText = _cleanTextForTranslation(text);
    Logs().i('[Translator] Clean text: "$cleanText"');
    
    if (cleanText.trim().isEmpty) {
      Logs().i('[Translator] Empty text after cleaning, skipping');
      return null;
    }
    
    if (_isNumericOnly(cleanText.trim())) {
      Logs().i('[Translator] Numeric only text, skipping');
      return null;
    }
    
    final detectedLang = MessageTranslator.detectLanguage(cleanText);
    final actualTargetLang = await MessageTranslator.getTargetLanguage(detectedLang);
    
    Logs().i('[Translator] Detected: $detectedLang, Target: $actualTargetLang');
    
    // Если язык уже целевой, не переводим
    if (detectedLang == actualTargetLang) {
      Logs().i('[Translator] Same language detected, skipping');
      return null;
    }
    
    try {
      final translation = await _translateWithChunking(cleanText, detectedLang, actualTargetLang);
      Logs().i('[Translator] Translation result: "$translation"');
      
      if (translation != null && translation != cleanText && translation.trim().isNotEmpty) {
        return translation;
      }
    } catch (e) {
      Logs().w('Translation failed: $e');
    }
    
    Logs().i('[Translator] No valid translation found');
    return null;
  }
  
  static Future<String?> _translateWithChunking(String text, String fromLang, String toLang) async {
    if (text.length <= 450) {
      return await _translateChunk(text, fromLang, toLang);
    }
    
    final chunks = _smartSplitText(text, 450);
    final translations = <String>[];
    
    for (final chunk in chunks) {
      final translation = await _translateChunk(chunk, fromLang, toLang);
      if (translation == null) return null;
      translations.add(translation);
      await Future.delayed(const Duration(milliseconds: 200)); // Rate limiting
    }
    
    return translations.join(' ');
  }
  
  static List<String> _smartSplitText(String text, int maxLength) {
    if (text.length <= maxLength) return [text];
    
    final chunks = <String>[];
    var remaining = text;
    
    while (remaining.length > maxLength) {
      var splitIndex = maxLength;
      
      // Find last space, period, or comma before maxLength
      for (var i = maxLength - 1; i >= maxLength ~/ 2; i--) {
        if (RegExp(r'[\s.,;!?]').hasMatch(remaining[i])) {
          splitIndex = i + 1;
          break;
        }
      }
      
      chunks.add(remaining.substring(0, splitIndex).trim());
      remaining = remaining.substring(splitIndex).trim();
    }
    
    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }
  
  static Future<String?> _translateChunk(String text, String fromLang, String toLang) async {
    try {
      return await TranslationProviders.translateText(text, fromLang, toLang);
    } catch (e) {
      Logs().w('[Translator] Translation failed: $e');
      return null;
    }
  }
  

  
  static Future<void> _translateEventAsync(String eventId, String text, Function(String, String) onTranslated) async {
    Logs().i('[AutoTranslator] Processing event $eventId: "$text"');
    
    if (_translatingEvents.contains(eventId)) {
      Logs().i('[AutoTranslator] Event $eventId already translating, skipping');
      return;
    }
    
    // Ждем свободного слота для перевода
    while (_activeTranslations >= _maxConcurrentTranslations) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    _translatingEvents.add(eventId);
    _activeTranslations++;
    
    Logs().i('[AutoTranslator] Starting translation for event $eventId');
    
    try {
      final translation = await translateMessage(text, 'auto');
      
      if (translation != null && translation.trim().isNotEmpty) {
        Logs().i('[AutoTranslator] Translation success for $eventId: "$translation"');
        messageTranslations[eventId] = translation;
        notifyTranslationChanged();
        onTranslated(eventId, translation);
      } else {
        Logs().i('[AutoTranslator] No translation for event $eventId');
      }
    } catch (e) {
      Logs().w('Translation failed for event $eventId: $e');
    } finally {
      _translatingEvents.remove(eventId);
      _activeTranslations--;
      Logs().i('[AutoTranslator] Finished processing event $eventId');
    }
  }

  static String detectLanguage(String text) {
    // Extended language detection
    final patterns = {
      'ru': RegExp(r'[а-яё]', caseSensitive: false),
      'en': RegExp(r'[a-z]', caseSensitive: false),
      'es': RegExp(r'[ñáéíóúü]', caseSensitive: false),
      'fr': RegExp(r'[àâäéèêëïîôöùûüÿç]', caseSensitive: false),
      'de': RegExp(r'[äöüß]', caseSensitive: false),
      'it': RegExp(r'[àèéìíîòóù]', caseSensitive: false),
      'pt': RegExp(r'[ãáâàéêíóôõú]', caseSensitive: false),
    };
    
    var maxMatches = 0;
    var detectedLang = 'auto';
    
    for (final entry in patterns.entries) {
      final matches = entry.value.allMatches(text).length;
      if (matches > maxMatches) {
        maxMatches = matches;
        detectedLang = entry.key;
      }
    }
    
    return maxMatches > 0 ? detectedLang : 'auto';
  }

  static Future<String> getTargetLanguage(String detectedLang) async {
    final prefs = await SharedPreferences.getInstance();
    final targetLang = prefs.getString(_targetLanguageKey) ?? 'auto';
    
    if (targetLang == 'auto') {
      // Auto mode: translate to opposite language
      switch (detectedLang) {
        case 'ru': return 'en';
        case 'en': return 'ru';
        default: return 'en';
      }
    }
    
    return targetLang;
  }
  
  static Future<String> get targetLanguage async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_targetLanguageKey) ?? 'auto';
  }
  
  static Future<void> setTargetLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetLanguageKey, language);
  }
  
  static String _cleanTextForTranslation(String text) {
    // Удаляем эмодзи и специальные символы, оставляем только текст для перевода
    return text
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '') // эмодзи
        .replaceAll(RegExp(r'[._]{2,}'), '') // удаляем повторяющиеся точки и подчеркивания
        .replaceAll(RegExp(r'[^\w\s.,;:!?()\[\]{}"\-А-Яа-яЁё]', unicode: true), '') // оставляем только буквы, цифры и базовую пунктуацию
        .replaceAll(RegExp(r'\s+'), ' ') // заменяем множественные пробелы одним
        .trim();
  }
  
  static bool _isNumericOnly(String text) {
    return RegExp(r'^\d+$').hasMatch(text) || 
           RegExp(r'^[\d\s.,;:!?()\[\]{}"\-+*/=<>%$@#&_~`|]+$').hasMatch(text);
  }
}