import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat_list/chat_list.dart';
import 'package:quikxchat/pages/chat_list/client_chooser_button.dart';
import 'package:quikxchat/utils/sync_status_localization.dart';
import '../../widgets/matrix.dart';

class ChatListHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;
  final bool globalSearch;

  const ChatListHeader({
    super.key,
    required this.controller,
    this.globalSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = Matrix.of(context).client;

    return SliverAppBar(
      floating: true,
      toolbarHeight: 60,
      pinned: QuikxChatThemes.isColumnMode(context),
      scrolledUnderElevation: 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              theme.colorScheme.surface.withValues(alpha: 0.05),
            ],
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      title: StreamBuilder(
        stream: client.onSyncStatus.stream,
        builder: (context, snapshot) {
          final status = client.onSyncStatus.value ??
              const SyncStatusUpdate(SyncStatus.waitingForResponse);
          final hide = client.onSync.value != null &&
              status.status != SyncStatus.error &&
              client.prevBatch != null;
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller.searchController,
              focusNode: controller.searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: (text) => controller.onSearchEnter(
                text,
                globalSearch: globalSearch,
              ),
              decoration: InputDecoration(
                filled: false,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                hintText: hide
                    ? L10n.of(context).searchChatsRooms
                    : status.calcLocalizedString(context),
                hintStyle: TextStyle(
                  color: status.error != null
                      ? Colors.orange
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: hide
                    ? controller.isSearchMode
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              tooltip: L10n.of(context).cancel,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: controller.cancelSearch,
                              color: theme.colorScheme.onSurface,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          )
                    : Container(
                        margin: const EdgeInsets.all(12),
                        width: 8,
                        height: 8,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            value: status.progress,
                            valueColor: status.error != null
                                ? const AlwaysStoppedAnimation<Color>(
                                    Colors.orange,
                                  )
                                : null,
                          ),
                        ),
                      ),
                suffixIcon: controller.isSearchMode && globalSearch
                    ? controller.isSearching
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextButton.icon(
                              onPressed: controller.setServer,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 14),
                              label: Text(
                                controller.searchServer ??
                                    Matrix.of(context).client.homeserver!.host,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                        child: ClientChooserButton(controller),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
