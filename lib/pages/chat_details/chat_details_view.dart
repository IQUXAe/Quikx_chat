import 'package:flutter/material.dart';
import 'package:quikxchat/widgets/modern_back_button.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat_details/chat_details.dart';
import 'package:quikxchat/pages/chat_details/participant_list_item.dart';

import 'package:quikxchat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/chat_settings_popup_menu.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/matrix.dart';
import '../../utils/url_launcher.dart';
import '../../widgets/mxc_image_viewer.dart';
import '../../widgets/qr_code_viewer.dart';

class ChatDetailsView extends StatelessWidget {
  final ChatDetailsController controller;

  const ChatDetailsView(this.controller, {super.key});

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final room = Matrix.of(context).client.getRoomById(controller.roomId!);
    if (room == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context).oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context).youAreNoLongerParticipatingInThisChat),
        ),
      );
    }

    final directChatMatrixID = room.directChatMatrixID;
    final roomAvatar = room.avatar;

    return StreamBuilder(
      stream: room.client.onRoomState.stream
          .where((update) => update.roomId == room.id),
      builder: (context, snapshot) {
        var members = room.getParticipants().toList()
          ..sort((b, a) => a.powerLevel.compareTo(b.powerLevel));
        members = members.take(10).toList();
        final actualMembersCount = (room.summary.mInvitedMemberCount ?? 0) +
            (room.summary.mJoinedMemberCount ?? 0);
        final canRequestMoreMembers = members.length < actualMembersCount;
        final displayname = room.getLocalizedDisplayname(
          MatrixLocals(L10n.of(context)),
        );
        return Scaffold(
          appBar: AppBar(
            leading: controller.widget.embeddedCloseButton ??
                Center(child: ModernBackButton()),
            elevation: theme.appBarTheme.elevation,
            actions: <Widget>[
              if (room.canonicalAlias.isNotEmpty)
                IconButton(
                  tooltip: L10n.of(context).share,
                  icon: const Icon(Icons.qr_code_rounded),
                  onPressed: () => showQrCodeViewer(
                    context,
                    room.canonicalAlias,
                  ),
                )
              else if (directChatMatrixID != null)
                IconButton(
                  tooltip: L10n.of(context).share,
                  icon: const Icon(Icons.qr_code_rounded),
                  onPressed: () => showQrCodeViewer(
                    context,
                    directChatMatrixID,
                  ),
                ),
              if (controller.widget.embeddedCloseButton == null)
                ChatSettingsPopupMenu(room, false),
            ],
            title: Text(L10n.of(context).chatDetails),
            backgroundColor: theme.appBarTheme.backgroundColor,
          ),
          body: MaxWidthBody(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: members.length + 1 + (canRequestMoreMembers ? 1 : 0),
              itemBuilder: (BuildContext context, int i) => i == 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            Stack(
                              children: [
                                Hero(
                                  tag:
                                      controller.widget.embeddedCloseButton !=
                                              null
                                          ? 'embedded_content_banner'
                                          : 'content_banner',
                                  child: Avatar(
                                    mxContent: room.avatar,
                                    name: displayname,
                                    size: Avatar.defaultSize * 3,
                                    onTap: roomAvatar != null
                                        ? () => showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  MxcImageViewer(roomAvatar),
                                            )
                                        : null,
                                  ),
                                ),
                                if (!room.isDirectChat &&
                                    room.canChangeStateEvent(
                                      EventTypes.RoomAvatar,
                                    ))
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: FloatingActionButton.small(
                                      onPressed: controller.setAvatarAction,
                                      heroTag: null,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayname,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (!room.isDirectChat)
                              TextButton.icon(
                                onPressed: () => context.push(
                                      '/rooms/${controller.roomId}/details/members',
                                    ),
                                icon: const Icon(
                                  Icons.group_outlined,
                                  size: 16,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      theme.colorScheme.secondary,
                                  iconColor: theme.colorScheme.secondary,
                                ),
                                label: Text(
                                  L10n.of(context).countParticipants(
                                    actualMembersCount,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (!room.isDirectChat && room.canChangeStateEvent(EventTypes.RoomName))
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: OutlinedButton.icon(
                                  onPressed: controller.setDisplaynameAction,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: Text(L10n.of(context).changeTheNameOfTheGroup),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 40),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (room.topic.isNotEmpty || room.canChangeStateEvent(EventTypes.RoomTopic))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          L10n.of(context).chatDescription,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (room.canChangeStateEvent(EventTypes.RoomTopic))
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            onPressed: controller.setTopicAction,
                                            tooltip: L10n.of(context).setChatDescription,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableLinkify(
                                      text: room.topic.isEmpty
                                          ? L10n.of(context).noChatDescriptionYet
                                          : room.topic,
                                      textScaleFactor:
                                          MediaQuery.textScalerOf(context).scale(1),
                                      options: const LinkifyOptions(humanize: false),
                                      linkStyle: TextStyle(
                                        color: theme.colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: room.topic.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                        color: room.topic.isEmpty
                                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                            : theme.colorScheme.onSurface,
                                      ),
                                      onOpen: (url) =>
                                          UrlLauncher(context, url.url).launchUrl(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _SettingsTile(
                                icon: Icons.insert_emoticon_outlined,
                                iconColor: Colors.amber,
                                title: L10n.of(context).customEmojisAndStickers,
                                onTap: controller.goToEmoteSettings,
                                isFirst: true,
                                isLast: room.isDirectChat,
                              ),
                              if (!room.isDirectChat) ...[
                                _SettingsTile(
                                  icon: Icons.shield_outlined,
                                  iconColor: Colors.blue,
                                  title: L10n.of(context).accessAndVisibility,
                                  onTap: () => context.push('/rooms/${room.id}/details/access'),
                                ),
                                _SettingsTile(
                                  icon: Icons.edit_attributes_outlined,
                                  iconColor: Colors.green,
                                  title: L10n.of(context).chatPermissions,
                                  onTap: () => context.push('/rooms/${room.id}/details/permissions'),
                                  isLast: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSection(
                          context,
                          title: L10n.of(context).countParticipants(actualMembersCount),
                          children: [],
                        ),
                        if (!room.isDirectChat && room.canInvite)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.primaryContainer,
                              child: ListTile(
                                leading: Icon(
                                  Icons.person_add_outlined,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                title: Text(
                                  L10n.of(context).inviteContact,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_outlined,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                onTap: () => context.go('/rooms/${room.id}/invite'),
                              ),
                            ),
                          ),
                      ],
                    )
                  : i < members.length + 1
                      ? ParticipantListItem(
                          members[i - 1],
                          isFirst: i == 1,
                          isLast: i == members.length && !canRequestMoreMembers,
                        )
                      : _LoadMoreTile(
                          actualMembersCount: actualMembersCount,
                          membersLength: members.length,
                          onTap: () => context.push(
                            '/rooms/${controller.roomId!}/details/members',
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}


class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5))
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}


class _LoadMoreTile extends StatelessWidget {
  final int actualMembersCount;
  final int membersLength;
  final VoidCallback onTap;

  const _LoadMoreTile({
    required this.actualMembersCount,
    required this.membersLength,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 4),
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
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.group_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                L10n.of(context).loadCountMoreParticipants(
                  actualMembersCount - membersLength,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
