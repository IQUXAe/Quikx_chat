import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/chat/events/message.dart';
import 'translation_cache.dart';
import 'translation_batch_processor.dart';
import 'translation_providers.dart';

class MessageTranslator {
  static const String _enabledKey = 'translation_enabled';
  static const String _targetLanguageKey = 'translation_target_language';
  static const String _autoTranslateKey = 'translation_auto_translate';
  
  static final _cache = TranslationCache();
  static final _batchProcessor = TranslationBatchProcessor();
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      await _cache.init();
      _initialized = true;
    }
  }
  
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
    await _cache.clear();
    messageTranslations.clear();
    notifyTranslationChanged();
    Logs().i('[MessageTranslator] Cache cleared');
  }

  static Future<String?> translateMessage(String text, String targetLang) async {
    await init();
    
    final cleanText = _cleanTextForTranslation(text);
    if (cleanText.trim().isEmpty || _isNumericOnly(cleanText.trim())) {
      return null;
    }
    
    final detectedLang = detectLanguage(cleanText);
    if (detectedLang == targetLang) {
      return null;
    }
    
    final cached = await _cache.get(cleanText, detectedLang, targetLang);
    if (cached != null) {
      return cached;
    }
    
    try {
      final translation = await _translateWithChunking(cleanText, detectedLang, targetLang);
      
      if (translation != null && translation != cleanText && translation.trim().isNotEmpty) {
        await _cache.put(cleanText, detectedLang, targetLang, translation);
        return translation;
      }
    } catch (e) {
      Logs().w('[Translator] Failed: $e');
    }
    
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
    return await _batchProcessor.translate(text, fromLang, toLang);
  }
  

  


  static String detectLanguage(String text) {
    final cleanText = text.trim();
    if (cleanText.length < 2) return 'auto';
    
    // Кириллица = Русский
    if (RegExp(r'[а-яёА-ЯЁ]').hasMatch(cleanText)) return 'ru';
    
    // Китайский/Японский/Корейский
    if (RegExp(r'[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]').hasMatch(text)) {
      if (RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text)) return 'ja';
      if (RegExp(r'[\uac00-\ud7af]').hasMatch(text)) return 'ko';
      return 'zh';
    }
    
    // Арабский
    if (RegExp(r'[\u0600-\u06ff]').hasMatch(text)) return 'ar';
    
    // Иврит
    if (RegExp(r'[\u0590-\u05ff]').hasMatch(text)) return 'he';
    
    // Тайский
    if (RegExp(r'[\u0e00-\u0e7f]').hasMatch(text)) return 'th';
    
    // Европейские языки по спецсимволам
    final lower = cleanText.toLowerCase();
    if (RegExp(r'[ñáéíóúü]').hasMatch(lower)) return 'es';
    if (RegExp(r'[àâäéèêëïîôöùûüÿç]').hasMatch(lower)) return 'fr';
    if (RegExp(r'[äöüß]').hasMatch(lower)) return 'de';
    if (RegExp(r'[ãõç]').hasMatch(lower)) return 'pt';
    
    // Латиница = Английский
    if (RegExp(r'[a-zA-Z]').hasMatch(cleanText)) return 'en';
    
    return 'auto';
  }

  static Future<String> getTargetLanguage(String detectedLang) async {
    final prefs = await SharedPreferences.getInstance();
    final targetLang = prefs.getString(_targetLanguageKey) ?? 'auto';
    
    if (targetLang == 'auto') {
      final systemLang = _getSystemLanguage();
      if (detectedLang == systemLang) return 'en';
      return systemLang;
    }
    
    return targetLang;
  }
  
  static String _getSystemLanguage() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return locale.split('_').first;
  }
  
  static Future<String> get targetLanguage async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_targetLanguageKey) ?? 'auto';
  }
  
  static Future<void> setTargetLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetLanguageKey, language);
  }
  
  static Future<bool> get autoTranslateEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoTranslateKey) ?? false;
  }
  
  static Future<void> setAutoTranslate(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTranslateKey, enabled);
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