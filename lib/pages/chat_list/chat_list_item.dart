import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:quikxchat/utils/room_status_extension.dart';
import 'package:quikxchat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:quikxchat/widgets/future_loading_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
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
        final avatarUri = await room.avatar!.getThumbnailUri(
          client,
          width: 56,
          height: 56,
        );
        if (mounted) {
          precacheImage(
            NetworkImage(avatarUri.toString()),
            context,
          ).catchError((e) => Logs().v('Failed to precache avatar: $e'));
        }
      }

      final directChatMatrixId = room.directChatMatrixID;
      if (directChatMatrixId != null) {
        try {
          final profile = await client.getProfileFromUserId(directChatMatrixId);
          if (profile.avatarUrl != null && mounted) {
            final profileUri = await profile.avatarUrl!.getThumbnailUri(
              client,
              width: 56,
              height: 56,
            );
            if (mounted) {
              precacheImage(
                NetworkImage(profileUri.toString()),
                context,
              ).catchError((e) => Logs().v('Failed to precache profile avatar: $e'));
            }
          }
          if (mounted) setState(() {});
        } catch (e) {
          Logs().v('Failed to load profile: $e');
        }
      }

      final space = widget.space;
      if (space?.avatar != null && mounted) {
        final spaceUri = await space!.avatar!.getThumbnailUri(
          client,
          width: 36,
          height: 36,
        );
        if (mounted) {
          precacheImage(
            NetworkImage(spaceUri.toString()),
            context,
          ).catchError((e) => Logs().v('Failed to precache space avatar: $e'));
        }
      }
    } catch (e) {
      Logs().v('Failed to preload profiles: $e');
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
            ? 22.0
            : 8.0
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

    return Material(
      color: widget.activeChat
          ? theme.colorScheme.primaryContainer
          : widget.room.isFavourite
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
              : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () => widget.onLongPress?.call(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(theme, space, directChatMatrixId, displayname),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitle(theme, displayname, isMuted, hasNotifications, lastEvent),
                    const SizedBox(height: 4),
                    _buildSubtitle(theme, typingText, ownMessage, lastEvent, isDirectChat, directChatMatrixId, unread),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildTrailing(theme, unreadBubbleSize, hasNotifications),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, Room? space, String? directChatMatrixId, String displayname) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (space != null)
            Positioned(
              top: -8,
              left: -8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Avatar(
                  borderRadius: BorderRadius.circular(16),
                  mxContent: space.avatar,
                  size: 24,
                  name: space.getLocalizedDisplayname(),
                  client: widget.room.client,
                  onTap: () => widget.onLongPress?.call(context),
                ),
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
                : const BorderRadius.all(Radius.circular(16)),
            mxContent: widget.room.avatar,
            size: 52,
            name: displayname,
            client: widget.room.client,
            presenceUserId: directChatMatrixId,
            presenceBackgroundColor: theme.colorScheme.surface,
            onTap: () => widget.onLongPress?.call(context),
          ),
        ],
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
                  ? FontWeight.w500
                  : FontWeight.w400,
              fontSize: 16,
              color: widget.room.isUnread || widget.room.hasNewMessages
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
        if (!widget.room.isSpace && lastEvent != null && widget.room.membership != Membership.invite)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              lastEvent.originServerTs.localizedTimeShort(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
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
          Icon(
            Icons.access_time,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
        ] else if (typingText.isEmpty && ownMessage && lastEvent != null) ...[
          Icon(
            MessageStatusHelper.isMessageRead(lastEvent) ? Icons.done_all : Icons.check,
            size: 14,
            color: MessageStatusHelper.isMessageRead(lastEvent)
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: widget.room.isSpace && widget.room.membership == Membership.join
              ? Text(
                  L10n.of(context).countChatsAndCountParticipants(
                    widget.room.spaceChildren.length,
                    (widget.room.summary.mJoinedMemberCount ?? 1),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                )
              : typingText.isNotEmpty
                  ? Text(
                      typingText,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        decoration: widget.room.lastEvent?.redacted == true ? TextDecoration.lineThrough : null,
                      ),
                    ),
        ),
        if (widget.room.isFavourite)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.push_pin,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing(ThemeData theme, double unreadBubbleSize, bool hasNotifications) {
    if (widget.onForget != null) {
      return IconButton(
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        onPressed: widget.onForget,
      );
    }

    if (widget.room.membership == Membership.invite) {
      return IconButton(
        tooltip: L10n.of(context).declineInvitation,
        icon: const Icon(Icons.delete_forever_rounded, size: 20),
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasNotifications)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
            decoration: BoxDecoration(
              color: widget.room.highlightCount > 0
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.room.notificationCount > 99 ? '99+' : widget.room.notificationCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else if (widget.room.isUnread || widget.room.hasNewMessages || widget.room.markedUnread)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        if (widget.room.pushRuleState != PushRuleState.notify)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.notifications_off,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }


}
