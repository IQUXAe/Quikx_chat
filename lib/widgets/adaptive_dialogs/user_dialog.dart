import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';


import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/date_time_extension.dart';

import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/presence_builder.dart';
import '../../utils/url_launcher.dart';
import '../future_loading_dialog.dart';
import '../hover_builder.dart';
import '../matrix.dart';
import '../mxc_image_viewer.dart';

class UserDialog extends StatelessWidget {
  static Future<void> show({
    required BuildContext context,
    required Profile profile,
    bool noProfileWarning = false,
  }) =>
      showAdaptiveDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => UserDialog(
          profile,
          noProfileWarning: noProfileWarning,
        ),
      );

  final Profile profile;
  final bool noProfileWarning;

  const UserDialog(this.profile, {this.noProfileWarning = false, super.key});

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final dmRoomId = client.getDirectChatFromUserId(profile.userId);
    final displayname = profile.displayName ??
        profile.userId.localpart ??
        L10n.of(context).user;
    var copied = false;
    final theme = Theme.of(context);
    final avatar = profile.avatarUrl;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: PresenceBuilder(
          userId: profile.userId,
          client: Matrix.of(context).client,
          builder: (context, presence) {
            final statusMsg = presence?.statusMsg;
            final lastActiveTimestamp = presence?.lastActiveTimestamp;
            final presenceText = presence?.currentlyActive == true
                ? L10n.of(context).currentlyActive
                : lastActiveTimestamp != null
                    ? L10n.of(context).lastActiveAgo(
                        lastActiveTimestamp.localizedTimeShort(context),
                      )
                    : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Avatar(
                  mxContent: avatar,
                  name: displayname,
                  size: Avatar.defaultSize * 2.8,
                  onTap: avatar != null
                      ? () => showDialog(
                            context: context,
                            builder: (_) => MxcImageViewer(avatar),
                          )
                      : null,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    displayname,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (presenceText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    presenceText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                HoverBuilder(
                  builder: (context, hovered) => StatefulBuilder(
                    builder: (context, setState) => MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: profile.userId),
                          );
                          setState(() {
                            copied = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: copied
                                ? theme.colorScheme.primaryContainer
                                : hovered
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                copied ? Icons.check : Icons.alternate_email,
                                size: 16,
                                color: copied
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  profile.userId,
                                  style: TextStyle(
                                    color: copied
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (statusMsg != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: SelectableLinkify(
                        text: statusMsg,
                        textScaleFactor:
                            MediaQuery.textScalerOf(context).scale(1),
                        textAlign: TextAlign.center,
                        options: const LinkifyOptions(humanize: false),
                        linkStyle: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        onOpen: (url) =>
                            UrlLauncher(context, url.url).launchUrl(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (client.userID != profile.userId)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final router = GoRouter.of(context);
                              final roomIdResult = await showFutureLoadingDialog(
                                context: context,
                                future: () => client.startDirectChat(profile.userId),
                              );
                              final roomId = roomIdResult.result;
                              if (roomId == null) return;
                              if (context.mounted) Navigator.of(context).pop();
                              router.go('/rooms/$roomId');
                            },
                            icon: const Icon(Icons.message_outlined, size: 18),
                            label: Text(
                              dmRoomId == null
                                  ? L10n.of(context).startConversation
                                  : L10n.of(context).sendAMessage,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final router = GoRouter.of(context);
                              Navigator.of(context).pop();
                              router.go(
                                '/rooms/settings/security/ignorelist',
                                extra: profile.userId,
                              );
                            },
                            icon: Icon(
                              Icons.block_outlined,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            label: Text(
                              L10n.of(context).ignoreUser,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: theme.colorScheme.errorContainer,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    L10n.of(context).close,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
