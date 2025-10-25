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
            backgroundColor: theme.colorScheme.surface,
            appBar: QuikxChatThemes.isColumnMode(context)
                ? null
                : AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    title: Text(L10n.of(context).settings, style: TextStyle(fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.only(bottom: 24),
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
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.secondaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2),
                                      width: 3,
                                    ),
                                  ),
                                  child: Avatar(
                                    mxContent: avatar,
                                    name: displayname,
                                    size: 72,
                                    onTap: avatar != null
                                        ? () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  MxcImageViewer(avatar),
                                            )
                                        : null,
                                  ),
                                ),
                                if (profile != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                        color: theme.colorScheme.onPrimary,
                                        onPressed: controller.setAvatarAction,
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: controller.setDisplaynameAction,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayname,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => FluffyShare.share(mxid, context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              mxid,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 14,
                                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (accountManageUrl != null || showChatBackupBanner != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        L10n.of(context).account,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (accountManageUrl != null)
                    SettingsCardTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 24),
                      ),
                      title: Text(L10n.of(context).manageAccount),
                      trailing: Icon(Icons.open_in_new_rounded, size: 20, color: theme.colorScheme.primary),
                      onTap: () => launchUrlString(
                        accountManageUrl,
                        mode: LaunchMode.inAppBrowserView,
                      ),
                      position: showChatBackupBanner != null ? CardPosition.first : CardPosition.single,
                    ),
                  if (showChatBackupBanner == null)
                    SettingsCardTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade400, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.backup_rounded, color: Colors.white, size: 24),
                      ),
                      title: Text(L10n.of(context).chatBackup),
                      trailing: const CircularProgressIndicator.adaptive(),
                      position: accountManageUrl != null ? CardPosition.last : CardPosition.single,
                    )
                  else
                    SettingsCardSwitch(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade400, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.backup_rounded, color: Colors.white, size: 24),
                      ),
                      title: Text(L10n.of(context).chatBackup),
                      value: controller.showChatBackupBanner == false,
                      onChanged: controller.firstRunBootstrapAction,
                      position: accountManageUrl != null ? CardPosition.last : CardPosition.single,
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      L10n.of(context).settings,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.palette_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).changeTheme),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    isActive: activeRoute.startsWith('/rooms/settings/style'),
                    onTap: controller.navigateToStyle,
                    position: CardPosition.first,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).notifications),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    isActive: activeRoute.startsWith('/rooms/settings/notifications'),
                    onTap: controller.navigateToNotifications,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.devices_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).devices),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    isActive: activeRoute.startsWith('/rooms/settings/devices'),
                    onTap: controller.navigateToDevices,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.indigo.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).chat),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    isActive: activeRoute.startsWith('/rooms/settings/chat'),
                    onTap: controller.navigateToChat,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.pink.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).security),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    isActive: activeRoute.startsWith('/rooms/settings/security'),
                    onTap: controller.navigateToSecurity,
                    position: CardPosition.last,
                  ),
                  const SizedBox(height: 20),
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      L10n.of(context).about,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.dns_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(
                      L10n.of(context).aboutHomeserver(
                        Matrix.of(context).client.userID?.domain ??
                            'homeserver',
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    isActive: activeRoute.startsWith('/rooms/settings/homeserver'),
                    onTap: controller.navigateToHomeserver,
                    position: CardPosition.first,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.green.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).privacy),
                    trailing: Icon(Icons.open_in_new_rounded, size: 20, color: theme.colorScheme.primary),
                    onTap: () => launchUrlString(AppConfig.privacyUrl),
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueGrey.shade400, Colors.blueGrey.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.info_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).about),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    onTap: () => _showAboutDialog(context),
                    position: CardPosition.last,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade400, Colors.red.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    ),
                    title: Text(L10n.of(context).logout, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
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
