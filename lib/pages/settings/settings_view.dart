import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/env_config.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/fluffy_share.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/navigation_rail.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';
import '../../widgets/mxc_image_viewer.dart';
import 'settings.dart';
import '../../widgets/about_app_dialog.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;

  const SettingsView(this.controller, {super.key});



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showChatBackupBanner = controller.showChatBackupBanner;
    final activeRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final accountManageUrl = Matrix.of(context)
        .client
        .wellKnown
        ?.additionalProperties
        .tryGetMap<String, Object?>('org.matrix.msc2965.authentication')
        ?.tryGet<String>('account');
    
    return Row(
      children: [
        if (QuikxChatThemes.isColumnMode(context)) ...[
          SpacesNavigationRail(
            activeSpaceId: null,
            onGoToChats: () => context.go('/rooms'),
            onGoToSpaceId: (spaceId) => context.go('/rooms?spaceId=$spaceId'),
          ),
          Container(color: Theme.of(context).dividerColor, width: 1),
        ],
        Expanded(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: theme.colorScheme.primary,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: FutureBuilder<Profile>(
                      future: controller.profileFuture,
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        final avatar = profile?.avatarUrl;
                        final mxid = Matrix.of(context).client.userID ?? L10n.of(context).user;
                        final displayname = profile?.displayName ?? mxid.localpart ?? mxid;
                        
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.secondaryContainer,
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
                                GestureDetector(
                                  onTap: controller.setAvatarAction,
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
                                            size: 100,
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
                                          padding: const EdgeInsets.all(6),
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
                                            size: 16,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: controller.setDisplaynameAction,
                                  child: Text(
                                    displayname,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => FluffyShare.share(mxid, context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
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
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.copy,
                                          size: 14,
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
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (accountManageUrl != null || showChatBackupBanner != null)
                        _buildSection(
                          context,
                          title: L10n.of(context).account,
                          children: [
                            if (accountManageUrl != null)
                              SettingsCardTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.manage_accounts, color: Colors.cyan),
                                ),
                                title: Text(L10n.of(context).manageAccount),
                                trailing: const Icon(Icons.open_in_new, size: 20),
                                onTap: () => launchUrlString(accountManageUrl, mode: LaunchMode.inAppBrowserView),
                                position: showChatBackupBanner == null ? CardPosition.single : CardPosition.first,
                              ),
                            if (showChatBackupBanner == null)
                              SettingsCardTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.backup, color: Colors.amber),
                                ),
                                title: Text(L10n.of(context).chatBackup),
                                trailing: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                position: accountManageUrl != null ? CardPosition.last : CardPosition.single,
                              )
                            else
                              SettingsCardSwitch(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.backup, color: Colors.amber),
                                ),
                                title: Text(L10n.of(context).chatBackup),
                                value: showChatBackupBanner == false,
                                onChanged: controller.firstRunBootstrapAction,
                                position: accountManageUrl != null ? CardPosition.last : CardPosition.single,
                              ),
                          ],
                        ),
                      _buildSection(
                        context,
                        title: L10n.of(context).settings,
                        children: [
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.palette, color: Colors.purple),
                            ),
                            title: Text(L10n.of(context).changeTheme),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToStyle,
                            isActive: activeRoute.startsWith('/rooms/settings/style'),
                            position: CardPosition.first,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.notifications, color: Colors.orange),
                            ),
                            title: Text(L10n.of(context).notifications),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToNotifications,
                            isActive: activeRoute.startsWith('/rooms/settings/notifications'),
                            position: CardPosition.middle,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.devices, color: Colors.green),
                            ),
                            title: Text(L10n.of(context).devices),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToDevices,
                            isActive: activeRoute.startsWith('/rooms/settings/devices'),
                            position: CardPosition.middle,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chat_bubble, color: Colors.blue),
                            ),
                            title: Text(L10n.of(context).chat),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToChat,
                            isActive: activeRoute.startsWith('/rooms/settings/chat'),
                            position: CardPosition.middle,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.security, color: Colors.red),
                            ),
                            title: Text(L10n.of(context).security),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToSecurity,
                            isActive: activeRoute.startsWith('/rooms/settings/security'),
                            position: CardPosition.middle,
                          ),
                          if (!kIsWeb)
                            Builder(
                              builder: (context) {
                                final isConfigured = EnvConfig.v2tServerUrl.isNotEmpty && EnvConfig.v2tSecretKey.isNotEmpty;
                                return Opacity(
                                  opacity: isConfigured ? 1.0 : 0.5,
                                  child: IgnorePointer(
                                    ignoring: !isConfigured,
                                    child: SettingsCardTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isConfigured
                                              ? Colors.deepPurple.withValues(alpha: 0.1)
                                              : Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.auto_awesome,
                                          color: isConfigured ? Colors.deepPurple : Colors.grey,
                                        ),
                                      ),
                                      title: const Text('AI'),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () => context.go('/rooms/settings/ai'),
                                      isActive: activeRoute.startsWith('/rooms/settings/ai'),
                                      position: CardPosition.last,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: L10n.of(context).about,
                        children: [
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.dns, color: Colors.indigo),
                            ),
                            title: Text(L10n.of(context).aboutHomeserver(
                              Matrix.of(context).client.userID?.domain ?? 'homeserver',
                            ),),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToHomeserver,
                            isActive: activeRoute.startsWith('/rooms/settings/homeserver'),
                            position: CardPosition.first,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.privacy_tip, color: Colors.teal),
                            ),
                            title: Text(L10n.of(context).privacy),
                            trailing: const Icon(Icons.open_in_new, size: 20),
                            onTap: () => launchUrlString(AppConfig.privacyUrl),
                            position: CardPosition.middle,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.info, color: Colors.blueGrey),
                            ),
                            title: Text(L10n.of(context).about),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => AboutAppDialog.show(context),
                            position: CardPosition.last,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildLogoutButton(context),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...children,
        ],
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
          onTap: controller.logoutAction,
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
