import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';
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

class _ChatListItemState extends State<ChatListItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadProfiles();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _preloadProfiles() async {
    if (!mounted) return;

    try {
      final room = widget.room;
      final client = room.client;

      if (room.avatar != null) {
        precacheImage(
          NetworkImage(
            room.avatar!
                .getThumbnail(
                  client,
                  width: 56,
                  height: 56,
                )
                .toString(),
          ),
          context,
        ).catchError((_) {});
      }

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
                      width: 56,
                      height: 56,
                    )
                    .toString(),
              ),
              context,
            ).catchError((_) {});
          }
          if (mounted) setState(() {});
        } catch (e) {}
      }

      final space = widget.space;
      if (space?.avatar != null && mounted) {
        precacheImage(
          NetworkImage(
            space!.avatar!
                .getThumbnail(
                  client,
                  width: 36,
                  height: 36,
                )
                .toString(),
          ),
          context,
        ).catchError((_) {});
      }
    } catch (e) {}
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
            ? 24.0
            : 16.0
        : 0.0;
    final hasNotifications = widget.room.notificationCount > 0;
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

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: widget.activeChat
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : theme.colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(
              color: widget.activeChat
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: () => widget.onLongPress?.call(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _buildAvatar(theme, space, directChatMatrixId, displayname),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitle(theme, displayname, isMuted, hasNotifications, lastEvent),
                          const SizedBox(height: 4),
                          _buildSubtitle(theme, typingText, ownMessage, lastEvent, isDirectChat, directChatMatrixId, unread),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrailing(theme, unreadBubbleSize, hasNotifications),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, Room? space, String? directChatMatrixId, String displayname) {
    return HoverBuilder(
      builder: (context, hovered) => AnimatedScale(
        duration: QuikxChatThemes.animationDuration,
        curve: QuikxChatThemes.animationCurve,
        scale: hovered ? 1.08 : 1.0,
        child: SizedBox(
          width: 56,
          height: 56,
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
                      color: theme.colorScheme.surface,
                    ),
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius / 4),
                    mxContent: space.avatar,
                    size: 36,
                    name: space.getLocalizedDisplayname(),
                    client: widget.room.client,
                    onTap: () => widget.onLongPress?.call(context),
                  ),
                ),
              Avatar(
                border: space == null
                    ? widget.room.isSpace
                        ? BorderSide(width: 1, color: theme.dividerColor)
                        : null
                    : BorderSide(width: 2, color: theme.colorScheme.surface),
                borderRadius: widget.room.isSpace
                    ? BorderRadius.circular(AppConfig.borderRadius / 4)
                    : null,
                mxContent: widget.room.avatar,
                size: space != null ? 36 : 56,
                name: displayname,
                client: widget.room.client,
                presenceUserId: directChatMatrixId,
                presenceBackgroundColor: theme.colorScheme.surface,
                onTap: () => widget.onLongPress?.call(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, String displayname, bool isMuted, bool hasNotifications, Event? lastEvent) {
    return Row(
      children: [
        Expanded(
          child: Text(
            displayname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: widget.room.isUnread || widget.room.hasNewMessages
                  ? FontWeight.w700
                  : FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (isMuted)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 14,
              color: theme.colorScheme.outline,
            ),
          ),
        if (widget.room.isFavourite)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.push_pin_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        if (!widget.room.isSpace && lastEvent != null && widget.room.membership != Membership.invite)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              lastEvent.originServerTs.localizedTimeShort(context),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(ThemeData theme, String typingText, bool ownMessage, Event? lastEvent, bool isDirectChat, String? directChatMatrixId, bool unread) {
    return Row(
      children: [
        if (typingText.isEmpty && ownMessage && widget.room.lastEvent!.status.isSending) ...[
          const AnimatedLoadingIndicator(size: 16),
          const SizedBox(width: 6),
        ] else if (typingText.isEmpty && ownMessage && lastEvent != null) ...[
          Icon(
            MessageStatusHelper.isMessageRead(lastEvent) ? Icons.done_all_rounded : Icons.done_rounded,
            size: 16,
            color: MessageStatusHelper.isMessageRead(lastEvent)
                ? const Color(0xFF4CAF50)
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 6),
        ],
        if (typingText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.edit_rounded,
              color: theme.colorScheme.primary,
              size: 16,
            ),
          ),
        Expanded(
          child: widget.room.isSpace && widget.room.membership == Membership.join
              ? Text(
                  L10n.of(context).countChatsAndCountParticipants(
                    widget.room.spaceChildren.length,
                    (widget.room.summary.mJoinedMemberCount ?? 1),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 13,
                  ),
                )
              : typingText.isNotEmpty
                  ? Text(
                      typingText,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                    )
                  : Text(
                      widget.room.membership == Membership.invite
                          ? widget.room
                                  .getState(EventTypes.RoomMember, widget.room.client.userID!)
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
                                withSenderNamePrefix: (!isDirectChat || directChatMatrixId != widget.room.lastEvent?.senderId),
                              ) ??
                              L10n.of(context).emptyChat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread || widget.room.hasNewMessages
                            ? theme.colorScheme.onSurface.withOpacity(0.8)
                            : theme.colorScheme.outline,
                        fontSize: 13,
                        decoration: widget.room.lastEvent?.redacted == true ? TextDecoration.lineThrough : null,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTrailing(ThemeData theme, double unreadBubbleSize, bool hasNotifications) {
    if (widget.onForget != null) {
      return IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: widget.onForget,
      );
    }

    if (widget.room.membership == Membership.invite) {
      return IconButton(
        tooltip: L10n.of(context).declineInvitation,
        icon: const Icon(Icons.delete_forever_rounded),
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
      );
    }

    return AnimatedContainer(
      duration: QuikxChatThemes.animationDuration,
      curve: QuikxChatThemes.animationCurve,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: unreadBubbleSize,
      constraints: BoxConstraints(
        minWidth: unreadBubbleSize,
      ),
      decoration: BoxDecoration(
        gradient: widget.room.highlightCount > 0
            ? LinearGradient(
                colors: [
                  Color.lerp(theme.colorScheme.error, Colors.white, 0.15)!,
                  theme.colorScheme.error,
                  Color.lerp(theme.colorScheme.error, Colors.black, 0.2)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : hasNotifications || widget.room.markedUnread
                ? LinearGradient(
                    colors: [
                      Color.lerp(theme.colorScheme.primary, Colors.white, 0.15)!,
                      theme.colorScheme.primary,
                      Color.lerp(theme.colorScheme.primary, Colors.black, 0.2)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
        color: !hasNotifications && !widget.room.markedUnread && (widget.room.isUnread || widget.room.hasNewMessages)
            ? theme.colorScheme.primaryContainer
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasNotifications
            ? [
                BoxShadow(
                  color: (widget.room.highlightCount > 0 ? theme.colorScheme.error : theme.colorScheme.primary)
                      .withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: hasNotifications
          ? Text(
              widget.room.notificationCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            )
          : const SizedBox.shrink(),
    );
  }

  BorderRadius _getBorderRadius() {
    switch (widget.position) {
      case CardPosition.single:
        return BorderRadius.circular(16);
      case CardPosition.first:
        return const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        );
      case CardPosition.middle:
        return BorderRadius.zero;
      case CardPosition.last:
        return const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
    }
  }

  EdgeInsets _getMargin() {
    switch (widget.position) {
      case CardPosition.single:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CardPosition.first:
        return const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 1);
      case CardPosition.middle:
        return const EdgeInsets.only(left: 12, right: 12, top: 1, bottom: 1);
      case CardPosition.last:
        return const EdgeInsets.only(left: 12, right: 12, top: 1, bottom: 6);
    }
  }
}
