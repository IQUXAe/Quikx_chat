import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/member_actions_popup_menu_button.dart';
import '../../widgets/avatar.dart';

class ParticipantListItem extends StatelessWidget {
  final User user;
  final bool isFirst;
  final bool isLast;

  const ParticipantListItem(
    this.user, {
    super.key,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final membershipBatch = switch (user.membership) {
      Membership.ban => L10n.of(context).banned,
      Membership.invite => L10n.of(context).invited,
      Membership.join => null,
      Membership.knock => L10n.of(context).knocking,
      Membership.leave => L10n.of(context).leftTheChat,
    };

    final permissionBatch = user.powerLevel >= 100
        ? L10n.of(context).admin
        : user.powerLevel >= 50
            ? L10n.of(context).moderator
            : '';

    final displayName = user.calcDisplayname();
    final userName = user.id;

    final borderRadius = isFirst && isLast
        ? BorderRadius.circular(12)
        : isFirst
            ? const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              )
            : isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : BorderRadius.zero;

    final margin = isFirst && isLast
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
        : isFirst
            ? const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 1)
            : isLast
                ? const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 4)
                : const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 1);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showMemberActionsPopupMenu(context: context, user: user),
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Opacity(
                  opacity: user.membership == Membership.join ? 1 : 0.5,
                  child: Avatar(
                    mxContent: user.avatarUrl,
                    name: displayName.isNotEmpty ? displayName : userName,
                    presenceUserId: user.stateKey,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName.isNotEmpty ? displayName : userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (permissionBatch.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.powerLevel >= 100
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                permissionBatch,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: user.powerLevel >= 100
                                      ? theme.colorScheme.onTertiary
                                      : theme.colorScheme.onTertiaryContainer,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (displayName.isNotEmpty && displayName != userName)
                        Text(
                          userName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      if (membershipBatch != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            membershipBatch,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}