import 'package:matrix/matrix.dart';

/// Утилиты для работы со статусами сообщений
class MessageStatusHelper {
  /// Проверяет, прочитано ли сообщение другими пользователями
  static bool isMessageRead(Event event) {
    final myUserId = event.room.client.userID;
    
    // Если это не мое сообщение, не проверяем статус
    if (event.senderId != myUserId) {
      return false;
    }
    
    // Проверяем receipts на сообщении (исключаем себя)
    return event.receipts.any((r) => r.user.id != myUserId);
  }
  
  /// Получает количество пользователей, прочитавших сообщение
  static int getReadByCount(Event event) {
    final myUserId = event.room.client.userID;
    return event.receipts.where((r) => r.user.id != myUserId).length;
  }
  
  /// Получает список пользователей, прочитавших сообщение
  static List<User> getReadByUsers(Event event) {
    final myUserId = event.room.client.userID;
    return event.receipts
        .where((r) => r.user.id != myUserId)
        .map((r) => r.user)
        .toList();
  }
  
  /// Проверяет, нужно ли обновить статус сообщения
  static bool shouldUpdateStatus(Event event, int previousReceiptsCount) {
    return event.receipts.length != previousReceiptsCount;
  }
  
  /// Создает уникальный ключ для статуса сообщения
  static String createStatusKey(Event event) {
    final myUserId = event.room.client.userID;
    final receiptsCount = event.receipts.where((r) => r.user.id != myUserId).length;
    return '${event.eventId}_${event.status}_${receiptsCount}';
  }
}