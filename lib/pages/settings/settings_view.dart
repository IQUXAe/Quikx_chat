import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:quikxchat/config/app_config.dart';
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
                                Color.lerp(theme.colorScheme.primary, Colors.black, 0.2)!,
                                Color.lerp(theme.colorScheme.secondary, Colors.black, 0.2)!,
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
                                                color: Colors.black.withOpacity(0.3),
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
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: controller.setDisplaynameAction,
                                  child: Text(
                                    displayname,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => FluffyShare.share(mxid, context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          mxid,
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
                                    color: Colors.cyan.withOpacity(0.1),
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
                                    color: Colors.amber.withOpacity(0.1),
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
                                    color: Colors.amber.withOpacity(0.1),
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
                                color: Colors.purple.withOpacity(0.1),
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
                                color: Colors.orange.withOpacity(0.1),
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
                                color: Colors.green.withOpacity(0.1),
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
                                color: Colors.blue.withOpacity(0.1),
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
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.security, color: Colors.red),
                            ),
                            title: Text(L10n.of(context).security),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToSecurity,
                            isActive: activeRoute.startsWith('/rooms/settings/security'),
                            position: CardPosition.last,
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
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.dns, color: Colors.indigo),
                            ),
                            title: Text(L10n.of(context).aboutHomeserver(
                              Matrix.of(context).client.userID?.domain ?? 'homeserver',
                            )),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: controller.navigateToHomeserver,
                            isActive: activeRoute.startsWith('/rooms/settings/homeserver'),
                            position: CardPosition.first,
                          ),
                          SettingsCardTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
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
                                color: Colors.blueGrey.withOpacity(0.1),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.pink.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.logoutAction,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  L10n.of(context).logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
