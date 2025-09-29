import 'package:flutter_test/flutter_test.dart';
import 'package:quikxchat/utils/global_cache.dart';

void main() {
  group('GlobalCache Tests', () {
    late GlobalCache<String, String> cache;

    setUp(() {
      cache = GlobalCache<String, String>(maxSize: 3);
    });

    tearDown(() {
      cache.dispose();
    });

    test('should store and retrieve values', () {
      cache.put('key1', 'value1');
      expect(cache.get('key1'), 'value1');
    });

    test('should return null for non-existent keys', () {
      expect(cache.get('nonexistent'), isNull);
    });

    test('should respect max size limit', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      cache.put('key3', 'value3');
      cache.put('key4', 'value4'); // Should evict key1
      
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), 'value2');
      expect(cache.get('key3'), 'value3');
      expect(cache.get('key4'), 'value4');
      expect(cache.length, 3);
    });

    test('should clear all values', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      
      cache.clear();
      
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
      expect(cache.length, 0);
    });

    test('should remove specific keys', () {
      cache.put('key1', 'value1');
      cache.put('key2', 'value2');
      
      cache.remove('key1');
      
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), 'value2');
      expect(cache.length, 1);
    });
  });

  group('AppCaches Tests', () {
    tearDown(() {
      AppCaches.disposeAll();
    });

    test('should provide access to all cache types', () {
      expect(AppCaches.profiles, isA<GlobalCache<String, Map<String, dynamic>>>());
      expect(AppCaches.avatars, isA<GlobalCache<String, String>>());
      expect(AppCaches.eventContents, isA<GlobalCache<String, Map<String, dynamic>>>());
      expect(AppCaches.translations, isA<GlobalCache<String, String>>());
    });

    test('should return cache statistics', () {
      final stats = AppCaches.getStats();
      
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('profiles'), isTrue);
      expect(stats.containsKey('avatars'), isTrue);
      expect(stats.containsKey('eventContents'), isTrue);
      expect(stats.containsKey('translations'), isTrue);
    });

    test('should clear all caches', () {
      // Добавляем данные в кэши
      AppCaches.profiles.put('test', {'name': 'test'});
      AppCaches.avatars.put('test', 'avatar_url');
      
      expect(AppCaches.profiles.length, 1);
      expect(AppCaches.avatars.length, 1);
      
      // Очищаем все кэши
      AppCaches.clearAll();
      
      expect(AppCaches.profiles.length, 0);
      expect(AppCaches.avatars.length, 0);
    });
  });
}
