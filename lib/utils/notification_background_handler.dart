import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/client_download_content_extension.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/utils/push_helper.dart';

@pragma('vm:entry-point')
Future<void> notificationTap(
  NotificationResponse notificationResponse, {
  GoRouter? router,
  required Client client,
  L10n? l10n,
}) async {
  Logs().d(
    'Notification action handler started',
    notificationResponse.notificationResponseType.name,
  );
  final payload =
      QuikxChatPushPayload.fromString(notificationResponse.payload ?? '');
  switch (notificationResponse.notificationResponseType) {
    case NotificationResponseType.selectedNotification:
      final roomId = payload.roomId;
      if (roomId == null) return;

      if (router == null) {
        Logs().v('Ignore select notification action in background mode');
        return;
      }
      Logs().v('Open room from notification tap', roomId);
      await client.roomsLoading;
      await client.accountDataLoading;
      if (client.getRoomById(roomId) == null) {
        await client
            .waitForRoomInSync(roomId)
            .timeout(const Duration(seconds: 30));
      }
      router.go(
        client.getRoomById(roomId)?.membership == Membership.invite
            ? '/rooms'
            : '/rooms/$roomId',
      );
    case NotificationResponseType.selectedNotificationAction:
      final actionType = QuikxChatNotificationActions.values.singleWhereOrNull(
        (action) => action.name == notificationResponse.actionId,
      );
      if (actionType == null) {
        throw Exception('Selected notification with action but no action ID');
      }
      final roomId = payload.roomId;
      if (roomId == null) {
        throw Exception('Selected notification with action but no payload');
      }
      await client.roomsLoading;
      await client.accountDataLoading;
      await client.userDeviceKeysLoading;
      final room = client.getRoomById(roomId);
      if (room == null) {
        throw Exception(
          'Selected notification with action but unknown room $roomId',
        );
      }
      switch (actionType) {
        case QuikxChatNotificationActions.markAsRead:
          await room.setReadMarker(
            payload.eventId ?? room.lastEvent!.eventId,
            mRead: payload.eventId ?? room.lastEvent!.eventId,
            public: AppConfig.sendPublicReadReceipts,
          );
        case QuikxChatNotificationActions.reply:
          final input = notificationResponse.input;
          if (input == null || input.isEmpty) {
            throw Exception(
              'Selected notification with reply action but without input',
            );
          }

          final eventId = await room.sendTextEvent(
            input,
            parseCommands: false,
            displayPendingEvent: false,
          );

          if (PlatformInfos.isAndroid) {
            final ownProfile = await room.client.fetchOwnProfile();
            final avatar = ownProfile.avatarUrl;
            final avatarFile = avatar == null
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
                    .timeout(const Duration(seconds: 3));
            final messagingStyleInformation =
                await AndroidFlutterLocalNotificationsPlugin()
                    .getActiveNotificationMessagingStyle(room.id.hashCode);
            if (messagingStyleInformation == null) return;
            l10n ??= await lookupL10n(PlatformDispatcher.instance.locale);
            messagingStyleInformation.messages?.add(
              Message(
                input,
                DateTime.now(),
                Person(
                  key: room.client.userID,
                  name: l10n.you,
                  icon: avatarFile == null
                      ? null
                      : ByteArrayAndroidIcon(avatarFile),
                ),
              ),
            );

            await FlutterLocalNotificationsPlugin().show(
              room.id.hashCode,
              room.getLocalizedDisplayname(MatrixLocals(l10n)),
              input,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  AppConfig.pushNotificationsChannelId,
                  l10n.incomingMessages,
                  category: AndroidNotificationCategory.message,
                  shortcutId: room.id,
                  styleInformation: messagingStyleInformation,
                  groupKey: room.id,
                  playSound: false,
                  enableVibration: false,
                  actions: <AndroidNotificationAction>[
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
                ),
              ),
              payload: QuikxChatPushPayload(
                client.clientName,
                room.id,
                eventId,
              ).toString(),
            );
          }
      }
  }
}
