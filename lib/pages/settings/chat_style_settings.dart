import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/env_config.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/fluffy_share.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/matrix.dart';

import '../../widgets/mxc_image_viewer.dart';

class ChatStyleSettings extends StatelessWidget {
  final Future<Profile> profileFuture;
  final bool? showChatBackupBanner;
  final void Function() setDisplaynameAction;
  final void Function() setAvatarAction;
  final void Function() firstRunBootstrapAction;
  final void Function() logoutAction;
  final String? accountManageUrl;

  const ChatStyleSettings({
    required this.profileFuture,
    required this.showChatBackupBanner,
    required this.setDisplaynameAction,
    required this.setAvatarAction,
    required this.firstRunBootstrapAction,
    required this.logoutAction,
    required this.accountManageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final client = Matrix.of(context).client;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<Profile>(
                future: profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final avatar = profile?.avatarUrl;
                  final mxid = client.userID ?? L10n.of(context).user;
                  final displayname = profile?.displayName ?? mxid.localpart ?? mxid;

                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: setAvatarAction,
                            child: Stack(
                              children: [
                                Hero(
                                  tag: 'settings_avatar',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Avatar(
                                      mxContent: avatar,
                                      name: displayname,
                                      size: 80,
                                      onTap: avatar != null
                                          ? () => showDialog(
                                                context: context,
                                                builder: (_) => MxcImageViewer(avatar),
                                              )
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: setDisplaynameAction,
                            child: Text(
                              displayname,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => FluffyShare.share(mxid, context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mxid,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final items = _buildSettingsItems(context, activeRoute);
                if (index < items.length) {
                  return items[index];
                }
                // Добавляем кнопку выхода в конце
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildLogoutButton(context),
                  );
                }
                return null;
              },
              childCount: _buildSettingsItems(context, activeRoute).length + 1,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsItems(BuildContext context, String activeRoute) {
    final items = <Widget>[];

    // Секция "Аккаунт"
    items.add(_buildSectionHeader(context, L10n.of(context).account));
    
    if (accountManageUrl != null) {
      items.add(_buildSettingsItem(
        context: context,
        title: L10n.of(context).manageAccount,
        icon: Icons.manage_accounts,
        iconColor: Colors.cyan,
        onTap: () => launchUrlString(accountManageUrl!, mode: LaunchMode.inAppBrowserView),
      ));
    }

    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).chatBackup,
      icon: Icons.backup,
      iconColor: Colors.amber,
      trailing: showChatBackupBanner == true
          ? null
          : const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
      onTap: showChatBackupBanner == true ? firstRunBootstrapAction : null,
    ));

    // Секция "Настройки"
    items.add(_buildSectionHeader(context, L10n.of(context).settings));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).changeTheme,
      icon: Icons.palette,
      iconColor: Colors.purple,
      isActive: activeRoute.startsWith('/rooms/settings/style'),
      onTap: () => context.go('/rooms/settings/style'),
    ));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).notifications,
      icon: Icons.notifications,
      iconColor: Colors.orange,
      isActive: activeRoute.startsWith('/rooms/settings/notifications'),
      onTap: () => context.go('/rooms/settings/notifications'),
    ));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).devices,
      icon: Icons.devices,
      iconColor: Colors.green,
      isActive: activeRoute.startsWith('/rooms/settings/devices'),
      onTap: () => context.go('/rooms/settings/devices'),
    ));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).chat,
      icon: Icons.chat_bubble,
      iconColor: Colors.blue,
      isActive: activeRoute.startsWith('/rooms/settings/chat'),
      onTap: () => context.go('/rooms/settings/chat'),
    ));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).security,
      icon: Icons.security,
      iconColor: Colors.red,
      isActive: activeRoute.startsWith('/rooms/settings/security'),
      onTap: () => context.go('/rooms/settings/security'),
    ));

    // Условия для AI опций
    if (EnvConfig.v2tServerUrl.isNotEmpty && EnvConfig.v2tSecretKey.isNotEmpty) {
      items.add(_buildSettingsItem(
        context: context,
        title: 'AI',
        icon: Icons.auto_awesome,
        iconColor: Colors.deepPurple,
        isActive: activeRoute.startsWith('/rooms/settings/ai'),
        onTap: () => context.go('/rooms/settings/ai'),
      ));
    }

    // Секция "О приложении"
    items.add(_buildSectionHeader(context, L10n.of(context).about));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).aboutHomeserver(
        Matrix.of(context).client.userID?.domain ?? 'homeserver',
      ),
      icon: Icons.dns,
      iconColor: Colors.indigo,
      isActive: activeRoute.startsWith('/rooms/settings/homeserver'),
      onTap: () => context.go('/rooms/settings/homeserver'),
    ));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).privacy,
      icon: Icons.privacy_tip,
      iconColor: Colors.teal,
      onTap: () => launchUrlString(AppConfig.privacyUrl),
    ));
    
    items.add(_buildSettingsItem(
      context: context,
      title: L10n.of(context).about,
      icon: Icons.info,
      iconColor: Colors.blueGrey,
      onTap: () => showAboutDialog(context: context),
    ));

    return items;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    Widget? trailing,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    final itemColor = isActive
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: itemColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.error,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: logoutAction,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  L10n.of(context).logout,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}