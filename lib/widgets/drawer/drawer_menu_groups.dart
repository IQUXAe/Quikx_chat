import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/drawer/drawer_menu_item.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';

class DrawerMenuGroups extends StatelessWidget {
  final List<Animation<double>> itemAnimations;
  final Function(BuildContext) onCheckUpdates;
  final Function(BuildContext) onShowAbout;

  const DrawerMenuGroups({
    super.key,
    required this.itemAnimations,
    required this.onCheckUpdates,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildSettingsGroup(context),
        const SizedBox(height: 16),
        _buildActionsGroup(context),
        const SizedBox(height: 16),
        _buildInfoGroup(context),
      ],
    );
  }

  Widget _buildSettingsGroup(BuildContext context) {
    return Column(
      children: [
        DrawerMenuItem(
          icon: Icons.settings_outlined,
          iconColor: Colors.grey,
          title: L10n.of(context).settings,
          onTap: () => context.go('/rooms/settings'),
          position: CardPosition.first,
          animation: itemAnimations[0],
        ),
        DrawerMenuItem(
          icon: Icons.security_outlined,
          iconColor: Colors.red,
          title: L10n.of(context).security,
          onTap: () => context.go('/rooms/settings/security'),
          position: CardPosition.middle,
          animation: itemAnimations[1],
        ),
        DrawerMenuItem(
          icon: Icons.notifications_outlined,
          iconColor: Colors.orange,
          title: L10n.of(context).notifications,
          onTap: () => context.go('/rooms/settings/notifications'),
          position: CardPosition.middle,
          animation: itemAnimations[2],
        ),
        DrawerMenuItem(
          icon: Icons.palette_outlined,
          iconColor: Colors.purple,
          title: L10n.of(context).changeTheme,
          onTap: () => context.go('/rooms/settings/style'),
          position: CardPosition.last,
          animation: itemAnimations[3],
        ),
      ],
    );
  }

  Widget _buildActionsGroup(BuildContext context) {
    return Column(
      children: [
        DrawerMenuItem(
          icon: Icons.archive_outlined,
          iconColor: Colors.brown,
          title: L10n.of(context).archive,
          onTap: () => context.go('/rooms/archive'),
          position: CardPosition.first,
          animation: itemAnimations[4],
        ),
        DrawerMenuItem(
          icon: Icons.group_add_outlined,
          iconColor: Colors.green,
          title: L10n.of(context).newGroup,
          onTap: () => context.go('/rooms/newgroup'),
          position: CardPosition.middle,
          animation: itemAnimations[5],
        ),
        DrawerMenuItem(
          icon: Icons.workspaces_outlined,
          iconColor: Colors.blue,
          title: L10n.of(context).newSpace,
          onTap: () => context.go('/rooms/newspace'),
          position: CardPosition.last,
          animation: itemAnimations[6],
        ),
      ],
    );
  }

  Widget _buildInfoGroup(BuildContext context) {
    return Column(
      children: [
        if (!kIsWeb)
          DrawerMenuItem(
            icon: Icons.system_update_outlined,
            iconColor: Colors.teal,
            title: L10n.of(context).checkUpdates,
            onTap: () => onCheckUpdates(context),
            closeDrawer: false,
            position: CardPosition.first,
            animation: itemAnimations[7],
          ),
        DrawerMenuItem(
          icon: Icons.info_outlined,
          iconColor: Colors.cyan,
          title: L10n.of(context).about,
          onTap: () => onShowAbout(context),
          closeDrawer: false,
          position: kIsWeb ? CardPosition.single : CardPosition.last,
          animation: itemAnimations[8],
        ),
      ],
    );
  }
}