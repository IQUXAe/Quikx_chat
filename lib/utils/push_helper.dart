import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_shortcuts_new/flutter_shortcuts_new.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/client_download_content_extension.dart';
import 'package:quikxchat/utils/client_manager.dart';
import 'package:quikxchat/utils/error_reporter.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/utils/network_error_handler.dart';
import 'package:quikxchat/utils/push_monitoring.dart';

const notificationAvatarDimension = 256;

Future<void> pushHelper(
  PushNotification notification, {
  Client? client,
  L10n? l10n,
  String? activeRoomId,
  required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  Function(NotificationResponse)? onNotificationResponse,
}) async {
  try {
    await _tryPushHelper(
      notification,
      client: client,
      l10n: l10n,
      activeRoomId: activeRoomId,
      flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
      onNotificationResponse: onNotificationResponse,
    );
  } catch (e, s) {
    Logs().e('Push Helper has crashed! Writing into temporary file', e, s);

    const ErrorReporter(null, 'Push Helper has crashed!')
        .writeToTemporaryErrorLogFile(e, s);

    l10n ??= await lookupL10n(const Locale('en'));
    // Показываем fallback уведомление только при критических ошибках
    flutterLocalNotificationsPlugin.show(
      notification.roomId?.hashCode ?? 0,
      l10n.newMessageInFluffyChat,
      l10n.openAppToReadMessages,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          AppConfig.pushNotificationsChannelId,
          l10n.incomingMessages,
          number: notification.counts?.unread,
          ticker: l10n.unreadChatsInApp(
            AppConfig.applicationName,
            (notification.counts?.unread ?? 0).toString(),
          ),
          importance: Importance.high,
          priority: Priority.max,
          shortcutId: notification.roomId,
        ),
      ),
    );
    // Записываем ошибку в мониторинг
    await PushMonitoring.recordPushReceived(
      roomId: notification.roomId ?? 'unknown',
      eventId: notification.eventId ?? 'unknown', 
      error: e.toString(),
    );
    
    Logs().e('[Push] ❌ Push helper crashed, showing fallback notification');
    
    rethrow;
  }
}

Future<void> _tryPushHelper(
  PushNotification notification, {
  Client? client,
  L10n? l10n,
  String? activeRoomId,
  required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  Function(NotificationResponse)? onNotificationResponse,
}) async {
  final isBackgroundMessage = client == null;
  Logs().v(
    'Push helper has been started (background=$isBackgroundMessage).',
    notification.toJson(),
  );

  if (notification.roomId != null &&
      activeRoomId == notification.roomId &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
    Logs().v('[Push] Room is in foreground. Stop push helper here.');
    // Записываем как успешно обработанное (комната открыта)
    await PushMonitoring.recordPushReceived(
      roomId: notification.roomId ?? 'unknown',
      eventId: notification.eventId ?? 'unknown',
    );
    return;
  }

  client ??= (await ClientManager.getClients(
    initialize: false,
    store: await SharedPreferences.getInstance(),
  ))
      .first;
  Event? event;
  
  try {
    event = await NetworkErrorHandler.executeWithNetworkWait(
      () => client!.getEventByPushNotification(
        notification,
        storeInDatabase: false,
      ).timeout(const Duration(seconds: 15)),
      maxRetries: 3,
      networkTimeout: const Duration(seconds: 45),
    );
  } catch (e) {
    // Записываем ошибку в мониторинг
    await PushMonitoring.recordPushReceived(
      roomId: notification.roomId ?? 'unknown',
      eventId: notification.eventId ?? 'unknown',
      error: NetworkErrorHandler.getErrorDescription(e),
    );
    
    Logs().e('Failed to get event after retries: ${NetworkErrorHandler.getErrorDescription(e)}');
    
    // Показываем fallback уведомление только если это не ошибка сети или таймаут
    final errorDescription = NetworkErrorHandler.getErrorDescription(e);
    if (!errorDescription.toLowerCase().contains('timeout') && 
        !errorDescription.toLowerCase().contains('network') &&
        !errorDescription.toLowerCase().contains('connection')) {
      l10n ??= await lookupL10n(const Locale('en'));
      
      await flutterLocalNotificationsPlugin.show(
        notification.roomId?.hashCode ?? 0,
        l10n.newMessageInFluffyChat,
        l10n.openAppToReadMessages,
        NotificationDetails(
          iOS: const DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            AppConfig.pushNotificationsChannelId,
            l10n.incomingMessages,
            number: notification.counts?.unread,
            importance: Importance.high,
            priority: Priority.max,
            shortcutId: notification.roomId,
          ),
        ),
      );
    } else {
      Logs().i('Skipping fallback notification due to network/timeout error');
    }
    return;
  }

  if (event == null) {
    Logs().v('Notification is a clearing indicator.');
    if (notification.counts?.unread == null ||
        notification.counts?.unread == 0) {
      await flutterLocalNotificationsPlugin.cancelAll();
    } else {
      // Make sure client is fully loaded and synced before dismiss notifications:
      await client.roomsLoading;
      await client.oneShotSync();
      final activeNotifications =
          await flutterLocalNotificationsPlugin.getActiveNotifications();
      for (final activeNotification in activeNotifications) {
        final room = client.rooms.singleWhereOrNull(
          (room) => room.id.hashCode == activeNotification.id,
        );
        if (room == null || !room.isUnreadOrInvited) {
          flutterLocalNotificationsPlugin.cancel(activeNotification.id!);
        }
      }
    }
    return;
  }
  Logs().v('Push helper got notification event of type ${event.type}.');

  if (event.type.startsWith('m.call')) {
    // make sure bg sync is on (needed to update hold, unhold events)
    // prevent over write from app life cycle change
    client.backgroundSync = true;
  }

  if (event.type == EventTypes.CallHangup) {
    client.backgroundSync = false;
  }

  if (event.type.startsWith('m.call') && event.type != EventTypes.CallInvite) {
    Logs().v('Push message is a m.call but not invite. Do not display.');
    return;
  }

  if ((event.type.startsWith('m.call') &&
          event.type != EventTypes.CallInvite) ||
      event.type == 'org.matrix.call.sdp_stream_metadata_changed') {
    Logs().v('Push message was for a call, but not call invite.');
    return;
  }

  l10n ??= await L10n.delegate.load(PlatformDispatcher.instance.locale);
  final matrixLocals = MatrixLocals(l10n);

  // Calculate the body
  String body;
  if (event.type == EventTypes.Encrypted) {
    body = '🔒 ${l10n.newMessageInFluffyChat}';
  } else {
    body = await event.calcLocalizedBody(
      matrixLocals,
      plaintextBody: true,
      withSenderNamePrefix: false,
      hideReply: true,
      hideEdit: true,
      removeMarkdown: true,
    );
  }

  // The person object for the android message style notification
  final avatar = event.room.avatar;
  final senderAvatar = event.room.isDirectChat
      ? avatar
      : event.senderFromMemoryOrFallback.avatarUrl;

  Uint8List? roomAvatarFile, senderAvatarFile;
  
  try {
    roomAvatarFile = avatar == null
        ? null
        : await client
            .downloadMxcCached(
              avatar,
              thumbnailMethod: ThumbnailMethod.crop,
              width: notificationAvatarDimension,
              height: notificationAvatarDimension,
              animated: false,
              isThumbnail: true,
              rounded: true,
            )
            .timeout(const Duration(seconds: 2));
  } catch (e, s) {
    Logs().e('Unable to get room avatar', e, s);
  }
  
  try {
    senderAvatarFile = event.room.isDirectChat
        ? roomAvatarFile
        : senderAvatar == null
            ? null
            : await client
                .downloadMxcCached(
                  senderAvatar,
                  thumbnailMethod: ThumbnailMethod.crop,
                  width: notificationAvatarDimension,
                  height: notificationAvatarDimension,
                  animated: false,
                  isThumbnail: true,
                  rounded: true,
                )
                .timeout(const Duration(seconds: 2));
  } catch (e, s) {
    Logs().e('Unable to get sender avatar', e, s);
  }

  final id = notification.roomId.hashCode;

  final senderName = event.senderFromMemoryOrFallback.calcDisplayname();
  // Show notification

  final newMessage = Message(
    body,
    event.originServerTs,
    Person(
      bot: event.messageType == MessageTypes.Notice,
      key: event.senderId,
      name: senderName,
      icon: senderAvatarFile == null
          ? null
          : ByteArrayAndroidIcon(senderAvatarFile),
    ),
  );

  final messagingStyleInformation = PlatformInfos.isAndroid
      ? await AndroidFlutterLocalNotificationsPlugin()
          .getActiveNotificationMessagingStyle(id)
      : null;
  messagingStyleInformation?.messages?.add(newMessage);

  final roomName = event.room.getLocalizedDisplayname(MatrixLocals(l10n));

  final notificationGroupId =
      event.room.isDirectChat ? 'directChats' : 'groupChats';
  final groupName = event.room.isDirectChat ? l10n.directChats : l10n.groups;

  final messageRooms = AndroidNotificationChannelGroup(
    notificationGroupId,
    groupName,
  );
  final roomsChannel = AndroidNotificationChannel(
    event.room.id,
    roomName,
    groupId: notificationGroupId,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannelGroup(messageRooms);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(roomsChannel);

  final messagingStyle = messagingStyleInformation ??
      MessagingStyleInformation(
        Person(
          name: senderName,
          icon: roomAvatarFile == null
              ? null
              : ByteArrayAndroidIcon(roomAvatarFile),
          key: event.roomId,
          important: event.room.isFavourite,
        ),
        conversationTitle: event.room.isDirectChat ? null : roomName,
        groupConversation: !event.room.isDirectChat,
        messages: [newMessage],
      );

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    AppConfig.pushNotificationsChannelId,
    l10n.incomingMessages,
    number: notification.counts?.unread,
    category: AndroidNotificationCategory.message,
    shortcutId: event.room.id,
    styleInformation: messagingStyle,
    ticker: event.calcLocalizedBodyFallback(
      matrixLocals,
      plaintextBody: true,
      withSenderNamePrefix: !event.room.isDirectChat,
      hideReply: true,
      hideEdit: true,
      removeMarkdown: true,
    ),
    importance: Importance.high,
    priority: Priority.max,
    groupKey: _getNotificationGroupKey(event.room),
    actions: event.type == EventTypes.RoomMember
        ? null
        : <AndroidNotificationAction>[
            AndroidNotificationAction(
              QuikxChatNotificationActions.reply.name,
              l10n.reply,
              inputs: [
                AndroidNotificationActionInput(
                  label: l10n.writeAMessage,
                ),
              ],
              cancelNotification: false,
              allowGeneratedReplies: true,
              semanticAction: SemanticAction.reply,
            ),
            AndroidNotificationAction(
              QuikxChatNotificationActions.markAsRead.name,
              l10n.markAsRead,
              semanticAction: SemanticAction.markAsRead,
            ),
          ],
  );
  const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  final title = event.room.getLocalizedDisplayname(MatrixLocals(l10n));

  if (PlatformInfos.isAndroid && messagingStyleInformation == null) {
    await _setShortcut(event, l10n, title, roomAvatarFile);
  }

  Logs().v('[Push] Showing notification for room: ${event.roomId}');
  
  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    platformChannelSpecifics,
    payload:
        QuikxChatPushPayload(client.clientName, event.room.id, event.eventId)
            .toString(),
  );
  
  // Записываем успешное получение уведомления
  await PushMonitoring.recordPushReceived(
    roomId: event.roomId ?? 'unknown',
    eventId: event.eventId,
  );
  
  Logs().i('[Push] ✅ Push notification processed successfully for room: ${event.roomId}');
  Logs().v('Push helper has been completed!');
}

class QuikxChatPushPayload {
  final String? clientName, roomId, eventId;

  QuikxChatPushPayload(this.clientName, this.roomId, this.eventId);

  factory QuikxChatPushPayload.fromString(String payload) {
    final parts = payload.split('|');
    if (parts.length != 3) {
      return QuikxChatPushPayload(null, null, null);
    }
    return QuikxChatPushPayload(parts[0], parts[1], parts[2]);
  }

  @override
  String toString() => '$clientName|$roomId|$eventId';
}

enum QuikxChatNotificationActions { markAsRead, reply }

/// Определяет ключ группы для уведомления
String _getNotificationGroupKey(Room room) {
  return room.spaceParents.firstOrNull?.roomId ?? 'rooms';
}

/// Creates a shortcut for Android platform but does not block displaying the
/// notification. This is optional but provides a nicer view of the
/// notification popup.
Future<void> _setShortcut(
  Event event,
  L10n l10n,
  String title,
  Uint8List? avatarFile,
) async {
  final flutterShortcuts = FlutterShortcuts();
  await flutterShortcuts.initialize(debug: !kReleaseMode);
  await flutterShortcuts.pushShortcutItem(
    shortcut: ShortcutItem(
      id: event.room.id,
      action: AppConfig.inviteLinkPrefix + event.room.id,
      shortLabel: title,
      conversationShortcut: true,
      icon: avatarFile == null ? null : base64Encode(avatarFile),
      shortcutIconAsset: avatarFile == null
          ? ShortcutIconAsset.androidAsset
          : ShortcutIconAsset.memoryAsset,
      isImportant: event.room.isFavourite,
    ),
  );
}
