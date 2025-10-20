import 'package:flutter_test/flutter_test.dart';
import 'package:quikxchat/utils/global_cache.dart';

void main() {
  group('Integration Tests', () {
    test('Cache system integration', () {
      // Создаем временные кэши для теста
      final profilesCache = GlobalCache<String, Map<String, dynamic>>(maxSize: 100);
      final avatarsCache = GlobalCache<String, String>(maxSize: 100);
      final translationsCache = GlobalCache<String, String>(maxSize: 100);

      // Тестируем интеграцию между различными кэшами
      profilesCache.put('user1', {'name': 'John', 'id': 'user1'});
      avatarsCache.put('user1', 'https://example.com/avatar.png');
      translationsCache.put('hello', 'привет');

      // Проверяем что данные сохранились
      expect(profilesCache.get('user1'), isNotNull);
      expect(avatarsCache.get('user1'), 'https://example.com/avatar.png');
      expect(translationsCache.get('hello'), 'привет');

      // Проверяем размеры
      expect(profilesCache.length, 1);
      expect(avatarsCache.length, 1);
      expect(translationsCache.length, 1);

      // Очищаем и проверяем
      profilesCache.clear();
      avatarsCache.clear();
      translationsCache.clear();
      
      expect(profilesCache.length, 0);
      expect(avatarsCache.length, 0);
      expect(translationsCache.length, 0);

      // Освобождаем ресурсы
      profilesCache.dispose();
      avatarsCache.dispose();
      translationsCache.dispose();
    });

    test('Performance under load', () {
      final cache = GlobalCache<String, String>(maxSize: 1000);
      final stopwatch = Stopwatch()..start();

      // Добавляем 1000 элементов
      for (var i = 0; i < 1000; i++) {
        cache.put('key$i', 'value$i');
      }

      stopwatch.stop();
      
      // Проверяем что операция выполнилась быстро
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(cache.length, 1000);

      // Проверяем поиск
      stopwatch.reset();
      stopwatch.start();
      
      for (var i = 0; i < 100; i++) {
        final value = cache.get('key$i');
        expect(value, 'value$i');
      }
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(10));

      cache.dispose();
    });

    test('Memory cleanup behavior', () {
      final cache = GlobalCache<String, String>(maxSize: 5);
      
      // Заполняем кэш
      for (var i = 0; i < 10; i++) {
        cache.put('key$i', 'value$i');
      }
      
      // Должно остаться только 5 элементов (LRU)
      expect(cache.length, 5);
      
      // Первые элементы должны быть удалены
      expect(cache.get('key0'), isNull);
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
      expect(cache.get('key3'), isNull);
      expect(cache.get('key4'), isNull);
      
      // Последние должны остаться
      expect(cache.get('key5'), 'value5');
      expect(cache.get('key6'), 'value6');
      expect(cache.get('key7'), 'value7');
      expect(cache.get('key8'), 'value8');
      expect(cache.get('key9'), 'value9');

      cache.dispose();
    });
  });
}
