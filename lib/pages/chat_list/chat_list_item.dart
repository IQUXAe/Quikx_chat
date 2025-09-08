import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:simplemessenger/config/app_config.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:simplemessenger/utils/room_status_extension.dart';
import 'package:simplemessenger/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:simplemessenger/widgets/animated_loading_indicator.dart';
import 'package:simplemessenger/widgets/future_loading_dialog.dart';
import 'package:simplemessenger/widgets/hover_builder.dart';
import '../../config/themes.dart';
import '../../utils/date_time_extension.dart';
import '../../widgets/avatar.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatefulWidget {
  final Room room;
  final Room? space;
  final bool activeChat;
  final void Function(BuildContext context)? onLongPress;
  final void Function()? onForget;
  final void Function() onTap;
  final String? filter;

  const ChatListItem(
    this.room, {
    this.activeChat = false,
    required this.onTap,
    this.onLongPress,
    this.onForget,
    this.filter,
    this.space,
    super.key,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  @override
  void initState() {
    super.initState();
    // Асинхронное обновление профилей чатов
    widget.room.client.onSync.stream.listen((_) async {
      if (mounted) {
        // Обновляем профили участников
        try {
          await widget.room.requestParticipants();
        } catch (_) {}
        if (mounted) setState(() {});
      }
    });
    
    // Немедленное обновление
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          await widget.room.requestParticipants();
          if (mounted) setState(() {});
        } catch (_) {}
      }
    });
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 1,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        clipBehavior: Clip.hardEdge,
        color: backgroundColor,
        child: HoverBuilder(
          builder: (context, listTileHovered) => ListTile(
              visualDensity: const VisualDensity(vertical: -0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              onLongPress: () => widget.onLongPress?.call(context),
              leading: HoverBuilder(
                builder: (context, hovered) => AnimatedScale(
                  duration: SimpleMessengerThemes.animationDuration,
                  curve: SimpleMessengerThemes.animationCurve,
                  scale: hovered ? 1.1 : 1.0,
                  child: SizedBox(
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
                                color: backgroundColor ??
                                    theme.colorScheme.surface,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppConfig.borderRadius / 4,
                              ),
                              mxContent: space.avatar,
                              size: Avatar.defaultSize * 0.75,
                              name: space.getLocalizedDisplayname(),
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
                              duration: SimpleMessengerThemes.animationDuration,
                              curve: SimpleMessengerThemes.animationCurve,
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
                            ? FontWeight.w500
                            : null,
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
                  ],
                  AnimatedContainer(
                    width: typingText.isEmpty ? 0 : 18,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    duration: SimpleMessengerThemes.animationDuration,
                    curve: SimpleMessengerThemes.animationCurve,
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.secondary,
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: widget.room.isSpace && widget.room.membership == Membership.join
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
                                                  widget.room.lastEvent?.senderId),
                                        ) ??
                                        L10n.of(context).emptyChat,
                                softWrap: false,
                                maxLines: widget.room.notificationCount >= 1 ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread || widget.room.hasNewMessages
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.outline,
                                  decoration: widget.room.lastEvent?.redacted == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: SimpleMessengerThemes.animationDuration,
                    curve: SimpleMessengerThemes.animationCurve,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    height: unreadBubbleSize,
                    width: !hasNotifications && !unread && !widget.room.hasNewMessages
                        ? 0
                        : (unreadBubbleSize - 9) *
                                widget.room.notificationCount.toString().length +
                            9,
                    decoration: BoxDecoration(
                      color: widget.room.highlightCount > 0
                          ? theme.colorScheme.error
                          : hasNotifications || widget.room.markedUnread
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: hasNotifications
                        ? Text(
                            widget.room.notificationCount.toString(),
                            style: TextStyle(
                              color: widget.room.highlightCount > 0
                                  ? theme.colorScheme.onError
                                  : hasNotifications
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onPrimaryContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
}
