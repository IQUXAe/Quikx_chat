import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/date_time_extension.dart';
import 'package:quikxchat/utils/fluffy_share.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/future_loading_dialog.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/mxc_image_viewer.dart';
import 'package:quikxchat/widgets/presence_builder.dart';
import '../../utils/url_launcher.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? roomId;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.roomId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Profile? _profile;
  bool _loading = true;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = Matrix.of(context).client;
      final profile = await client.getProfileFromUserId(widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = Matrix.of(context).client;
    final dmRoomId = client.getDirectChatFromUserId(widget.userId);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayname = _profile?.displayName ??
        widget.userId.localpart ??
        L10n.of(context).user;
    final avatar = _profile?.avatarUrl;

    final isOwnProfile = client.userID == widget.userId;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: Builder(
              builder: (context) => FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(theme.colorScheme.primary, Colors.white, 0.1)!,
                      Color.lerp(theme.colorScheme.secondary, Colors.white, 0.1)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Avatar(
                          mxContent: avatar,
                          name: displayname,
                          size: 100,
                          onTap: avatar != null
                              ? () => showDialog(
                                    context: context,
                                    builder: (_) => MxcImageViewer(avatar),
                                  )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayname,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => FluffyShare.share(widget.userId, context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.userId,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: PresenceBuilder(
              userId: widget.userId,
              client: client,
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

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            if (presenceText != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  presenceText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (statusMsg != null) ...[
                              const SizedBox(height: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                                    child: Text(
                                      L10n.of(context).about.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  Card(
                                    elevation: 0,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SelectableLinkify(
                                        text: statusMsg,
                                        textScaleFactor:
                                            MediaQuery.textScalerOf(context).scale(1),
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
                              ),
                            ],
                            if (!isOwnProfile) ...[
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () async {
                                  final router = GoRouter.of(context);
                                  final roomIdResult = await showFutureLoadingDialog(
                                    context: context,
                                    future: () =>
                                        client.startDirectChat(widget.userId),
                                  );
                                  final roomId = roomIdResult.result;
                                  if (roomId == null || !context.mounted) return;
                                  router.go('/rooms/$roomId');
                                },
                                icon: const Icon(Icons.send_outlined),
                                label: Text(
                                  dmRoomId == null
                                      ? L10n.of(context).startConversation
                                      : L10n.of(context).sendAMessage,
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final router = GoRouter.of(context);
                                  router.go(
                                    '/rooms/settings/security/ignorelist',
                                    extra: widget.userId,
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
                                  minimumSize: const Size.fromHeight(50),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: theme.colorScheme.error),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
