import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';
import 'package:quikxchat/widgets/tap_scale_animation.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:quikxchat/utils/room_status_extension.dart';
import 'package:quikxchat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:quikxchat/widgets/animated_loading_indicator.dart';
import 'package:quikxchat/widgets/future_loading_dialog.dart';
import 'package:quikxchat/widgets/hover_builder.dart';
import '../../config/themes.dart';
import '../../utils/date_time_extension.dart';
import '../../widgets/avatar.dart';
import '../../utils/message_status_helper.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatefulWidget {
  final Room room;
  final Room? space;
  final bool activeChat;
  final void Function(BuildContext context)? onLongPress;
  final void Function()? onForget;
  final void Function() onTap;
  final String? filter;
  final CardPosition position;

  const ChatListItem(
    this.room, {
    this.activeChat = false,
    required this.onTap,
    this.onLongPress,
    this.onForget,
    this.filter,
    this.space,
    this.position = CardPosition.single,
    super.key,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  @override
  void initState() {
    super.initState();
    // Асинхронная предзагрузка профилей и аватаров
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadProfiles();
    });
  }

  Future<void> _preloadProfiles() async {
    if (!mounted) return;

    try {
      final room = widget.room;
      final client = room.client;

      // Предзагружаем аватар комнаты
      if (room.avatar != null) {
        precacheImage(
          NetworkImage(
            room.avatar!
                .getThumbnail(
                  client,
                  width: 44,
                  height: 44,
                )
                .toString(),
          ),
          context,
        ).catchError((_) {});
      }

      // Предзагружаем профиль для прямых чатов
      final directChatMatrixId = room.directChatMatrixID;
      if (directChatMatrixId != null) {
        try {
          final profile = await client.getProfileFromUserId(directChatMatrixId);
          if (profile.avatarUrl != null && mounted) {
            precacheImage(
              NetworkImage(
                profile.avatarUrl!
                    .getThumbnail(
                      client,
                      width: 44,
                      height: 44,
                    )
                    .toString(),
              ),
              context,
            ).catchError((_) {});
          }
          if (mounted) setState(() {}); // Обновляем UI с новыми данными
        } catch (e) {
          // Игнорируем ошибки загрузки профиля
        }
      }

      // Предзагружаем аватар пространства если есть
      final space = widget.space;
      if (space?.avatar != null && mounted) {
        precacheImage(
          NetworkImage(
            space!.avatar!
                .getThumbnail(
                  client,
                  width: 33,
                  height: 33,
                )
                .toString(),
          ),
          context,
        ).catchError((_) {});
      }
    } catch (e) {
      // Игнорируем ошибки предзагрузки
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isMuted = widget.room.pushRuleState != PushRuleState.notify;
    final typingText = widget.room.getLocalizedTypingText(context);
    final lastEvent = widget.room.lastEvent;
    final ownMessage = lastEvent?.senderId == widget.room.client.userID;
    final unread = widget.room.isUnread;
    final directChatMatrixId = widget.room.directChatMatrixID;
    final isDirectChat = directChatMatrixId != null;
    final unreadBubbleSize = unread || widget.room.hasNewMessages
        ? widget.room.notificationCount > 0
            ? 20.0
            : 14.0
        : 0.0;
    final hasNotifications = widget.room.notificationCount > 0;
    final backgroundColor =
        widget.activeChat ? theme.colorScheme.secondaryContainer : null;
    final displayname = widget.room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)),
    );
    final filter = widget.filter;
    if (filter != null && !displayname.toLowerCase().contains(filter)) {
      return const SizedBox.shrink();
    }

    final space = widget.space;

    final borderRadius = _getBorderRadius();
    final margin = _getMargin();

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: widget.activeChat
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.hardEdge,
        child: HoverBuilder(
          builder: (context, listTileHovered) => ListTile(
            visualDensity: const VisualDensity(vertical: -2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onLongPress: () => widget.onLongPress?.call(context),
            leading: HoverBuilder(
              builder: (context, hovered) => AnimatedScale(
                duration: QuikxChatThemes.animationDuration,
                curve: QuikxChatThemes.animationCurve,
                scale: hovered ? 1.1 : 1.0,
                child: Container(
                  width: Avatar.defaultSize,
                  height: Avatar.defaultSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (space != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Avatar(
                            border: BorderSide(
                              width: 2,
                              color:
                                  backgroundColor ?? theme.colorScheme.surface,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConfig.borderRadius / 4,
                            ),
                            mxContent: space.avatar,
                            size: Avatar.defaultSize * 0.75,
                            name: space.getLocalizedDisplayname(),
                            client: widget.room.client,
                            onTap: () => widget.onLongPress?.call(context),
                          ),
                        ),
                      // Центрируем основную аватарку
                      Align(
                        alignment: Alignment.center,
                        child: Avatar(
                          border: space == null
                              ? widget.room.isSpace
                                  ? BorderSide(
                                      width: 1,
                                      color: theme.dividerColor,
                                    )
                                  : null
                              : BorderSide(
                                  width: 2,
                                  color: backgroundColor ??
                                      theme.colorScheme.surface,
                                ),
                          borderRadius: widget.room.isSpace
                              ? BorderRadius.circular(
                                  AppConfig.borderRadius / 4,
                                )
                              : null,
                          mxContent: widget.room.avatar,
                          size: space != null
                              ? Avatar.defaultSize * 0.75
                              : Avatar.defaultSize,
                          name: displayname,
                          client: widget.room.client,
                          presenceUserId: directChatMatrixId,
                          presenceBackgroundColor: backgroundColor,
                          onTap: () => widget.onLongPress?.call(context),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => widget.onLongPress?.call(context),
                          child: AnimatedScale(
                            duration: QuikxChatThemes.animationDuration,
                            curve: QuikxChatThemes.animationCurve,
                            scale: listTileHovered ? 1.0 : 0.0,
                            child: Material(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              child: const Icon(
                                Icons.arrow_drop_down_circle_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    displayname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontWeight: unread || widget.room.hasNewMessages
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isMuted)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      size: 16,
                    ),
                  ),
                if (widget.room.isFavourite)
                  Padding(
                    padding: EdgeInsets.only(
                      right: hasNotifications ? 4.0 : 0.0,
                    ),
                    child: Icon(
                      Icons.push_pin,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (!widget.room.isSpace &&
                    lastEvent != null &&
                    widget.room.membership != Membership.invite)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      lastEvent.originServerTs.localizedTimeShort(context),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (typingText.isEmpty &&
                    ownMessage &&
                    widget.room.lastEvent!.status.isSending) ...[
                  const AnimatedLoadingIndicator(size: 16),
                  const SizedBox(width: 4),
                ] else if (typingText.isEmpty &&
                    ownMessage &&
                    lastEvent != null) ...[
                  // Показываем статус последнего сообщения в списке чатов
                  Icon(
                    MessageStatusHelper.isMessageRead(lastEvent)
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: MessageStatusHelper.isMessageRead(lastEvent)
                        ? const Color(0xFF4CAF50)
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                ],
                AnimatedContainer(
                  width: typingText.isEmpty ? 0 : 18,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  duration: QuikxChatThemes.animationDuration,
                  curve: QuikxChatThemes.animationCurve,
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.secondary,
                    size: 14,
                  ),
                ),
                Expanded(
                  child: widget.room.isSpace &&
                          widget.room.membership == Membership.join
                      ? Text(
                          L10n.of(context).countChatsAndCountParticipants(
                            widget.room.spaceChildren.length,
                            (widget.room.summary.mJoinedMemberCount ?? 1),
                          ),
                          style: TextStyle(color: theme.colorScheme.outline),
                        )
                      : typingText.isNotEmpty
                          ? Text(
                              typingText,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              softWrap: false,
                            )
                          : Text(
                              widget.room.membership == Membership.invite
                                  ? widget.room
                                          .getState(
                                            EventTypes.RoomMember,
                                            widget.room.client.userID!,
                                          )
                                          ?.content
                                          .tryGet<String>('reason') ??
                                      (isDirectChat
                                          ? L10n.of(context).newChatRequest
                                          : L10n.of(context).inviteGroupChat)
                                  : lastEvent?.calcLocalizedBodyFallback(
                                        MatrixLocals(L10n.of(context)),
                                        hideReply: true,
                                        hideEdit: true,
                                        plaintextBody: true,
                                        removeMarkdown: true,
                                        withSenderNamePrefix: (!isDirectChat ||
                                            directChatMatrixId !=
                                                widget
                                                    .room.lastEvent?.senderId),
                                      ) ??
                                      L10n.of(context).emptyChat,
                              softWrap: false,
                              maxLines:
                                  widget.room.notificationCount >= 1 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread || widget.room.hasNewMessages
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.outline,
                                decoration:
                                    widget.room.lastEvent?.redacted == true
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: QuikxChatThemes.animationDuration,
                  curve: QuikxChatThemes.animationCurve,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  height: unreadBubbleSize,
                  width: !hasNotifications &&
                          !unread &&
                          !widget.room.hasNewMessages
                      ? 0
                      : (unreadBubbleSize - 9) *
                              widget.room.notificationCount.toString().length +
                          9,
                  decoration: BoxDecoration(
                    gradient: widget.room.highlightCount > 0
                        ? LinearGradient(
                            colors: [
                              Color.lerp(
                                  theme.colorScheme.error, Colors.white, 0.1)!,
                              Color.lerp(
                                  theme.colorScheme.error, Colors.black, 0.3)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : hasNotifications || widget.room.markedUnread
                            ? LinearGradient(
                                colors: [
                                  Color.lerp(theme.colorScheme.primary,
                                      Colors.white, 0.1)!,
                                  Color.lerp(theme.colorScheme.primary,
                                      Colors.black, 0.3)!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                    color: !hasNotifications && !widget.room.markedUnread
                        ? theme.colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: hasNotifications
                        ? [
                            BoxShadow(
                              color: (widget.room.highlightCount > 0
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary)
                                  .withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: hasNotifications
                      ? Text(
                          widget.room.notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            onTap: widget.onTap,
            trailing: widget.onForget == null
                ? widget.room.membership == Membership.invite
                    ? IconButton(
                        tooltip: L10n.of(context).declineInvitation,
                        icon: const Icon(Icons.delete_forever_outlined),
                        color: theme.colorScheme.error,
                        onPressed: () async {
                          final consent = await showOkCancelAlertDialog(
                            context: context,
                            title: L10n.of(context).declineInvitation,
                            message: L10n.of(context).areYouSure,
                            okLabel: L10n.of(context).yes,
                            isDestructive: true,
                          );
                          if (consent != OkCancelResult.ok) return;
                          if (!context.mounted) return;
                          await showFutureLoadingDialog(
                            context: context,
                            future: widget.room.leave,
                          );
                        },
                      )
                    : null
                : IconButton(
                    icon: const Icon(Icons.delete_outlined),
                    onPressed: widget.onForget,
                  ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    switch (widget.position) {
      case CardPosition.single:
        return BorderRadius.circular(12);
      case CardPosition.first:
        return const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        );
      case CardPosition.middle:
        return BorderRadius.zero;
      case CardPosition.last:
        return const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        );
    }
  }

  EdgeInsets _getMargin() {
    switch (widget.position) {
      case CardPosition.single:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 4);
      case CardPosition.first:
        return const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 0);
      case CardPosition.middle:
        return const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0);
      case CardPosition.last:
        return const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 4);
    }
  }
}
