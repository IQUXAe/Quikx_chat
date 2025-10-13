import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/app_version.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/fluffy_share.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/navigation_rail.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';
import '../../widgets/mxc_image_viewer.dart';
import 'settings.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;

  const SettingsView(this.controller, {super.key});



  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConfig.applicationName,
        applicationVersion: AppVersion.version,
        applicationIcon: Image.asset('assets/logo.png', width: 64, height: 64),
        children: [
          Text(L10n.of(context).simpleSecureMessaging),
          const SizedBox(height: 16),
          Text(L10n.of(context).developerIquxae),
          const SizedBox(height: 8),
          Text(L10n.of(context).builtWithFlutter),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showChatBackupBanner = controller.showChatBackupBanner;
    final activeRoute =
        GoRouter.of(context).routeInformationProvider.value.uri.path;
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
          Container(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ],
        Expanded(
          child: Scaffold(
            appBar: QuikxChatThemes.isColumnMode(context)
                ? null
                : AppBar(
                    title: Text(L10n.of(context).settings),
                    leading: Center(
                      child: BackButton(
                        onPressed: () => context.go('/rooms'),
                      ),
                    ),
                  ),
            body: ListTileTheme(
              iconColor: theme.colorScheme.onSurface,
              child: ListView(
                key: const Key('SettingsListViewContent'),
                children: <Widget>[
                  FutureBuilder<Profile>(
                    future: controller.profileFuture,
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final avatar = profile?.avatarUrl;
                      final mxid = Matrix.of(context).client.userID ??
                          L10n.of(context).user;
                      final displayname =
                          profile?.displayName ?? mxid.localpart ?? mxid;
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Stack(
                              children: [
                                Avatar(
                                  mxContent: avatar,
                                  name: displayname,
                                  size: Avatar.defaultSize * 2.5,
                                  onTap: avatar != null
                                      ? () => showDialog(
                                            context: context,
                                            builder: (_) =>
                                                MxcImageViewer(avatar),
                                          )
                                      : null,
                                ),
                                if (profile != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: FloatingActionButton.small(
                                      elevation: 2,
                                      onPressed: controller.setAvatarAction,
                                      heroTag: null,
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton.icon(
                                  onPressed: controller.setDisplaynameAction,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                    iconColor: theme.colorScheme.onSurface,
                                  ),
                                  label: Text(
                                    displayname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      FluffyShare.share(mxid, context),
                                  icon: const Icon(
                                    Icons.copy_outlined,
                                    size: 14,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.secondary,
                                    iconColor: theme.colorScheme.secondary,
                                  ),
                                  label: Text(
                                    mxid,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    //    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Группа аккаунта
                  if (accountManageUrl != null)
                    SettingsCardTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_circle_outlined, color: Colors.cyan),
                      ),
                      title: Text(L10n.of(context).manageAccount),
                      trailing: const Icon(Icons.open_in_new_outlined),
                      onTap: () => launchUrlString(
                        accountManageUrl,
                        mode: LaunchMode.inAppBrowserView,
                      ),
                      position: showChatBackupBanner != null ? CardPosition.first : CardPosition.single,
                    ),
                  if (showChatBackupBanner == null)
                    SettingsCardTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.backup_outlined, color: Colors.amber),
                      ),
                      title: Text(L10n.of(context).chatBackup),
                      trailing: const CircularProgressIndicator.adaptive(),
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
                        child: const Icon(Icons.backup_outlined, color: Colors.amber),
                      ),
                      title: Text(L10n.of(context).chatBackup),
                      value: controller.showChatBackupBanner == false,
                      onChanged: controller.firstRunBootstrapAction,
                      position: accountManageUrl != null ? CardPosition.last : CardPosition.single,
                    ),
                  const SizedBox(height: 16),
                  
                  // Группа основных настроек
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.palette_outlined, color: Colors.purple),
                    ),
                    title: Text(L10n.of(context).changeTheme),
                    isActive: activeRoute.startsWith('/rooms/settings/style'),
                    onTap: controller.navigateToStyle,
                    position: CardPosition.first,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.orange),
                    ),
                    title: Text(L10n.of(context).notifications),
                    isActive: activeRoute.startsWith('/rooms/settings/notifications'),
                    onTap: controller.navigateToNotifications,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.devices_outlined, color: Colors.green),
                    ),
                    title: Text(L10n.of(context).devices),
                    isActive: activeRoute.startsWith('/rooms/settings/devices'),
                    onTap: controller.navigateToDevices,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                    ),
                    title: Text(L10n.of(context).chat),
                    isActive: activeRoute.startsWith('/rooms/settings/chat'),
                    onTap: controller.navigateToChat,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.red),
                    ),
                    title: Text(L10n.of(context).security),
                    isActive: activeRoute.startsWith('/rooms/settings/security'),
                    onTap: controller.navigateToSecurity,
                    position: CardPosition.last,
                  ),
                  // VoIP temporarily disabled
                  // SettingsCardTile(
                  //   leading: Container(
                  //     padding: const EdgeInsets.all(8),
                  //     decoration: BoxDecoration(
                  //       color: Colors.deepPurple.withOpacity(0.1),
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: const Icon(Icons.call_outlined, color: Colors.deepPurple),
                  //   ),
                  //   title: const Text('Настройки VoIP'),
                  //   isActive: activeRoute.startsWith('/rooms/settings/voip'),
                  //   onTap: () => context.go('/rooms/settings/voip'),
                  //   position: CardPosition.last,
                  // ),

                  const SizedBox(height: 16),
                  
                  // Группа информации
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.dns_outlined, color: Colors.indigo),
                    ),
                    title: Text(
                      L10n.of(context).aboutHomeserver(
                        Matrix.of(context).client.userID?.domain ??
                            'homeserver',
                      ),
                    ),
                    isActive: activeRoute.startsWith('/rooms/settings/homeserver'),
                    onTap: controller.navigateToHomeserver,
                    position: CardPosition.first,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.privacy_tip_outlined, color: Colors.teal),
                    ),
                    title: Text(L10n.of(context).privacy),
                    onTap: () => launchUrlString(AppConfig.privacyUrl),
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                    ),
                    title: Text(L10n.of(context).about),
                    onTap: () => _showAboutDialog(context),
                    position: CardPosition.last,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Выход отдельно
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_outlined, color: Colors.pink),
                    ),
                    title: Text(L10n.of(context).logout),
                    onTap: controller.logoutAction,
                    position: CardPosition.single,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
