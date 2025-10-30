import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/date_time_extension.dart';
import 'package:quikxchat/widgets/adaptive_dialogs/adaptive_dialog_action.dart';
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
                const SizedBox(height: 32),
                Avatar(
                  mxContent: avatar,
                  name: displayname,
                  size: Avatar.defaultSize * 2.5,
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
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: copied
                                ? theme.colorScheme.primaryContainer
                                : hovered
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                copied ? Icons.check : Icons.alternate_email,
                                size: 14,
                                color: copied
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  profile.userId,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                if (presenceText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    presenceText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (statusMsg != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
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
                        style: theme.textTheme.bodyMedium,
                        onOpen: (url) =>
                            UrlLauncher(context, url.url).launchUrl(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (client.userID != profile.userId)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            icon: const Icon(Icons.send_outlined),
                            label: Text(
                              dmRoomId == null
                                  ? L10n.of(context).startConversation
                                  : L10n.of(context).sendAMessage,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              color: theme.colorScheme.error,
                            ),
                            label: Text(
                              L10n.of(context).ignoreUser,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text(L10n.of(context).close),
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
