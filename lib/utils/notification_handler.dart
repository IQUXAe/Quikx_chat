import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/utils/background_push.dart';
import 'package:quikxchat/widgets/quikx_chat_app.dart';

/// Утилита для обработки уведомлений
class NotificationHandler {
  /// Очередь отложенных действий уведомлений
  static final List<Map<String, dynamic>> _pendingNotificationActions = [];

  /// Обрабатывает ответ на уведомление
  @pragma('vm:entry-point')
  static void onNotificationResponse(NotificationResponse response) {
    Logs().d('=== NOTIFICATION HANDLER CALLED ===');
    Logs().d('[NotificationHandler] actionId: ${response.actionId}, payload: ${response.payload}, input: ${response.input}');

    try {
      if (response.actionId != null) {
        if (response.actionId!.startsWith('reply_')) {
          final roomId = response.actionId!.substring('reply_'.length);
          final message = response.input;
          Logs().d('[NotificationHandler] Reply: "$message" to room: $roomId');

          // Передаем обработку в BackgroundPush
          _handleNotificationAction('reply', roomId, message);

        } else if (response.actionId!.startsWith('mark_read_')) {
          final roomId = response.actionId!.substring('mark_read_'.length);
          Logs().d('[NotificationHandler] Mark read room: $roomId');

          _handleNotificationAction('mark_read', roomId, null);
        }
      } else {
        // Обычный клик по уведомлению
        var roomId = response.payload;
        if (roomId != null) {
          // Убираем префикс 'room:' если он есть
          if (roomId.startsWith('room:')) {
            roomId = roomId.substring(5);
          }
          Logs().d('[NotificationHandler] Open room: $roomId');

          // Открываем комнату через роутер
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              QuikxChatApp.router.go('/rooms/$roomId');
            } catch (e) {
              Logs().w('[NotificationHandler] Failed to navigate to room: $e');
            }
          });
        }
      }
    } catch (e, s) {
      Logs().w('[NotificationHandler] Error handling notification response: $e');
      Logs().w('[NotificationHandler] Stack trace: $s');
    }
  }

  /// Обрабатывает действия уведомлений через BackgroundPush
  static void _handleNotificationAction(String action, String roomId, String? input) {
    // Сохраняем действие для обработки после инициализации приложения
    _pendingNotificationActions.add({
      'action': action,
      'roomId': roomId,
      'input': input,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    Logs().d('[NotificationHandler] Queued notification action: $action for room $roomId');
  }

  /// Обрабатывает отложенные действия уведомлений
  static void processPendingNotificationActions(Client? client) {
    if (client == null || _pendingNotificationActions.isEmpty) {
      return;
    }

    Logs().d('[NotificationHandler] Processing ${_pendingNotificationActions.length} pending notification actions');

    // Обрабатываем только недавние действия (менее 5 минут)
    final now = DateTime.now().millisecondsSinceEpoch;
    final validActions = _pendingNotificationActions.where((action) {
      final timestamp = action['timestamp'] as int;
      return (now - timestamp) < 300000; // 5 минут
    }).toList();

    for (final action in validActions) {
      final actionType = action['action'] as String;
      final roomId = action['roomId'] as String;
      final input = action['input'] as String?;

      Logs().d('[NotificationHandler] Processing action: $actionType for room $roomId');

      // Отложенная обработка через BackgroundPush
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Получаем BackgroundPush из первого клиента
          final backgroundPush = BackgroundPush.clientOnly(client);

          if (actionType == 'reply' && input != null) {
            await backgroundPush.handleReplyAction(roomId, input);
          } else if (actionType == 'mark_read') {
            await backgroundPush.handleMarkAsReadAction(roomId);
          }
        } catch (e) {
          Logs().w('[NotificationHandler] Failed to process pending action: $e');
        }
      });
    }

    // Очищаем очередь
    _pendingNotificationActions.clear();
    Logs().d('[NotificationHandler] Processed and cleared pending notification actions');
  }
}
