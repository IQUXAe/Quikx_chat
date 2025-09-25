import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/widgets/quikx_chat_app.dart';

import 'background_push.dart';
import 'platform_infos.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  final List<Map<String, dynamic>> _pendingNotificationActions = [];

  NotificationService._internal();

  Future<void> initialize() async {
    final initialized = await localNotifications.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('notifications_icon'),
        linux: PlatformInfos.isLinux
            ? const LinuxInitializationSettings(
                defaultActionName: 'Open notification',
              )
            : null,
      ),
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
    );
    Logs().i('Push notification manager initialized: $initialized');
  }

  void onNotificationResponse(NotificationResponse response) {
    try {
      if (response.actionId != null) {
        _handleAction(response);
      } else {
        _handleNotificationClick(response);
      }
    } catch (e, s) {
      Logs().e('Error handling notification response', e, s);
    }
  }

  void _handleAction(NotificationResponse response) {
    final actionId = response.actionId!;
    if (actionId.startsWith('reply_')) {
      final roomId = actionId.substring('reply_'.length);
      final message = response.input;
      _queueAction('reply', roomId, message);
    } else if (actionId.startsWith('mark_read_')) {
      final roomId = actionId.substring('mark_read_'.length);
      _queueAction('mark_read', roomId, null);
    }
  }

  void _handleNotificationClick(NotificationResponse response) {
    var roomId = response.payload;
    if (roomId != null) {
      if (roomId.startsWith('room:')) {
        roomId = roomId.substring(5);
      }
      _navigateToRoom(roomId);
    }
  }

  void _navigateToRoom(String roomId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        QuikxChatApp.router.go('/rooms/$roomId');
      } catch (e) {
        Logs().e('Failed to navigate to room', e);
      }
    });
  }

  void _queueAction(String action, String roomId, String? input) {
    _pendingNotificationActions.add({
      'action': action,
      'roomId': roomId,
      'input': input,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void processPendingActions(Client? client) {
    if (client == null || _pendingNotificationActions.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final validActions = _pendingNotificationActions.where((action) {
      final timestamp = action['timestamp'] as int;
      return (now - timestamp) < 300000; // 5 minutes
    }).toList();

    for (final action in validActions) {
      final actionType = action['action'] as String;
      final roomId = action['roomId'] as String;
      final input = action['input'] as String?;

      _processAction(client, actionType, roomId, input);
    }
    _pendingNotificationActions.clear();
  }

  void _processAction(Client client, String actionType, String roomId, String? input) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final backgroundPush = BackgroundPush.clientOnly(client);
        if (actionType == 'reply' && input != null) {
          await backgroundPush.handleReplyAction(roomId, input);
        } else if (actionType == 'mark_read') {
          await backgroundPush.handleMarkAsReadAction(roomId);
        }
      } catch (e) {
        Logs().e('Failed to process pending action', e);
      }
    });
  }
}