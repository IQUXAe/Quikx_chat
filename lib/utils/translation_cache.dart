import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matrix/matrix.dart';

class TranslationCache {
  static const String _cachePrefix = 'trans_cache_';
  static const String _metaKey = 'trans_meta';
  static const int _maxCacheSize = 500;
  
  final Map<String, String> _memoryCache = {};
  List<String> _lruKeys = [];
  
  static final TranslationCache _instance = TranslationCache._();
  factory TranslationCache() => _instance;
  TranslationCache._();
  
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaJson = prefs.getString(_metaKey);
      if (metaJson != null) {
        _lruKeys = List<String>.from(json.decode(metaJson));
      }
    } catch (e) {
      Logs().w('[TranslationCache] Init failed: $e');
    }
  }
  
  String _makeKey(String text, String from, String to) {
    return '${text.hashCode}_${from}_$to';
  }
  
  Future<String?> get(String text, String from, String to) async {
    final key = _makeKey(text, from, to);
    
    if (_memoryCache.containsKey(key)) {
      _updateLRU(key);
      return _memoryCache[key];
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cachePrefix$key');
      if (cached != null) {
        _memoryCache[key] = cached;
        _updateLRU(key);
        return cached;
      }
    } catch (e) {
      Logs().v('[TranslationCache] Get failed: $e');
    }
    
    return null;
  }
  
  Future<void> put(String text, String from, String to, String translation) async {
    final key = _makeKey(text, from, to);
    _memoryCache[key] = translation;
    _updateLRU(key);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', translation);
      
      if (_lruKeys.length > _maxCacheSize) {
        await _evictOldest(prefs);
      }
      
      await _saveMeta(prefs);
    } catch (e) {
      Logs().w('[TranslationCache] Put failed: $e');
    }
  }
  
  void _updateLRU(String key) {
    _lruKeys.remove(key);
    _lruKeys.add(key);
  }
  
  Future<void> _evictOldest(SharedPreferences prefs) async {
    final toRemove = _lruKeys.length - _maxCacheSize;
    for (var i = 0; i < toRemove; i++) {
      final key = _lruKeys[i];
      _memoryCache.remove(key);
      await prefs.remove('$_cachePrefix$key');
    }
    _lruKeys = _lruKeys.sublist(toRemove);
  }
  
  Future<void> _saveMeta(SharedPreferences prefs) async {
    await prefs.setString(_metaKey, json.encode(_lruKeys));
  }
  
  Future<void> clear() async {
    _memoryCache.clear();
    _lruKeys.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      await prefs.remove(_metaKey);
    } catch (e) {
      Logs().w('[TranslationCache] Clear failed: $e');
    }
  }
  
  int get size => _lruKeys.length;
}
