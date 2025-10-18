import 'package:flutter_test/flutter_test.dart';
import 'package:quikxchat/utils/notification_deduplication.dart';

void main() {
  group('Push Notification System Tests', () {
    setUp(() {
      NotificationDeduplication.clearCache();
    });

    test('Deduplication prevents duplicate notifications', () {
      const roomId = '!test:example.com';
      const eventId = '\$event123';

      // Первое уведомление должно пройти
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId),
        false,
      );

      // Отмечаем как обработанное
      NotificationDeduplication.markAsProcessed(roomId, eventId);

      // Второе уведомление должно быть заблокировано
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId),
        true,
      );
    });

    test('Different events are not deduplicated', () {
      const roomId = '!test:example.com';
      const eventId1 = '\$event123';
      const eventId2 = '\$event456';

      NotificationDeduplication.markAsProcessed(roomId, eventId1);

      // Другое событие должно пройти
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId2),
        false,
      );
    });

    test('Cache can be cleared', () {
      const roomId = '!test:example.com';
      const eventId = '\$event123';

      NotificationDeduplication.markAsProcessed(roomId, eventId);
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId),
        true,
      );

      NotificationDeduplication.clearCache();

      // После очистки кэша уведомление должно пройти снова
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId),
        false,
      );
    });

    test('Remove from cache works correctly', () {
      const roomId = '!test:example.com';
      const eventId = '\$event123';

      NotificationDeduplication.markAsProcessed(roomId, eventId);
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId),
        true,
      );

      NotificationDeduplication.removeFromCache(roomId, eventId);

      // После удаления из кэша уведомление должно пройти
      expect(
        NotificationDeduplication.isAlreadyProcessed(roomId, eventId),
        false,
      );
    });

    test('Stats are tracked correctly', () {
      NotificationDeduplication.markAsProcessed('!room1:example.com', '\$event1');
      NotificationDeduplication.markAsProcessed('!room2:example.com', '\$event2');

      final stats = NotificationDeduplication.getStats();
      expect(stats['processed_count'], 2);
      expect(stats['cleanup_timers_count'], 2);
    });
  });
}
