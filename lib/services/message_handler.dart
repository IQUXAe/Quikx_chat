import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:unifiedpush/unifiedpush.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/file_logger.dart';
import 'package:quikxchat/utils/network_error_handler.dart';
import 'package:quikxchat/utils/notification_service.dart';
import 'package:quikxchat/utils/push_helper.dart';

class MessageHandler {
  final Client _client;
  final L10n? l10n;
  final MatrixState? matrix;

  MessageHandler(this._client, {this.l10n, this.matrix});

  Future<void> onUpMessage(PushMessage pushMessage, String i) async {
    final message = pushMessage.content;
    final messageStr = utf8.decode(message);

    if (kDebugMode) {
      Logs().i('[MessageHandler] === RECEIVED UP MESSAGE ===');
      Logs().i('[MessageHandler] Message length: ${message.length} bytes');
    }
    FileLogger.log('[MessageHandler] Received UP message: $messageStr');

    try {
      dynamic jsonData;
      try {
        jsonData = json.decode(messageStr);
      } catch (e) {
        Logs().w('[MessageHandler] Message is not valid JSON: ${e.toString()}');
        Logs().w('[MessageHandler] Raw message (first 200 chars): ${messageStr.length > 200 ? '${messageStr.substring(0, 200)}...' : messageStr}');
        if (messageStr.toLowerCase().contains('test') || messageStr.toLowerCase().contains('ping')) {
          Logs().i('[MessageHandler] Detected test message, showing test notification');
          await _showTestNotification(messageStr);
        }
        return;
      }

      if (jsonData is! Map<String, dynamic>) {
        Logs().w('[MessageHandler] JSON is not a map: ${jsonData.runtimeType}');
        return;
      }

      if (kDebugMode) {
        Logs().i('[MessageHandler] Parsed JSON keys: ${jsonData.keys.toList()}');
      }

      if (!jsonData.containsKey('notification')) {
        Logs().w('[MessageHandler] JSON does not contain notification field');
        if (jsonData.containsKey('data') || jsonData.containsKey('message')) {
          if (kDebugMode) {
            Logs().i('[MessageHandler] Found alternative data structure, attempting to process');
          }
        }
        return;
      }

      final data = Map<String, dynamic>.from(jsonData['notification']);
      data['devices'] ??= [];

      if (kDebugMode) {
        Logs().i('[MessageHandler] Processing notification data with keys: ${data.keys.toList()}');
        Logs().i('[MessageHandler] Room ID: ${data['room_id']}, Event ID: ${data['event_id']}');
      }

      if (data['room_id'] == null) {
        Logs().w('[MessageHandler] Missing room_id in notification data');
        return;
      }

      await NetworkErrorHandler.retryOnNetworkError(
        () => _processNotificationData(data),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
      );

      unawaited(_performReliableSyncWithService());

      Timer(const Duration(seconds: 30), () async {
        if (_client.onSyncStatus.value == SyncStatus.error) {
          Logs().w('[MessageHandler] Sync still in error state after 30s, forcing retry');
          unawaited(_performReliableSync());
        }
      });

      Logs().i('[MessageHandler] === NOTIFICATION PROCESSED SUCCESSFULLY ===');
    } catch (e, s) {
      Logs().e('[MessageHandler] Error processing UP message: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
      await _showFallbackNotification(e);
    }
  }

  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    final activeRoomId = matrix?.activeRoomId;
    await pushHelper(
      PushNotification.fromJson(data),
      client: _client,
      l10n: l10n,
      activeRoomId: activeRoomId,
      flutterLocalNotificationsPlugin: NotificationService.instance.localNotifications,
    );
  }

  Future<void> _showTestNotification(String message) async {
    try {
      await NotificationService.instance.localNotifications.show(
        999999,
        'UnifiedPush Test',
        'Test message received: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            'Test Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      Logs().e('[MessageHandler] Failed to show test notification', e);
    }
  }

  Future<void> _showFallbackNotification(dynamic error) async {
    try {
      await NotificationService.instance.localNotifications.show(
        999997,
        l10n?.newMessageInFluffyChat ?? 'New Message',
        l10n?.openAppToReadMessages ?? 'Open app to read messages',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'quikxchat_push',
            'Incoming Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      Logs().e('[MessageHandler] Failed to show fallback notification', e);
    }
  }

  Future<void> _performReliableSyncWithService() async {
    // This logic should be handled by a separate SyncService or within BackgroundPush
  }

  Future<void> _performReliableSync() async {
    // This logic should be handled by a separate SyncService or within BackgroundPush
  }
}