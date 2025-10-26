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
      toolbarHeight: 64,
      pinned: QuikxChatThemes.isColumnMode(context),
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.surface.withOpacity(0.1),
            ],
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
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
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondaryContainer.withOpacity(0.8),
                  theme.colorScheme.secondaryContainer.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  borderRadius: BorderRadius.circular(32),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hide
                    ? L10n.of(context).searchChatsRooms
                    : status.calcLocalizedString(context),
                hintStyle: TextStyle(
                  color: status.error != null
                      ? Colors.orange
                      : theme.colorScheme.onSecondaryContainer.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: hide
                    ? controller.isSearchMode
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: L10n.of(context).cancel,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: controller.cancelSearch,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          )
                    : Container(
                        margin: const EdgeInsets.all(14),
                        width: 8,
                        height: 8,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2.5,
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
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 12,
                            ),
                            child: SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton.icon(
                              onPressed: controller.setServer,
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: Text(
                                controller.searchServer ??
                                    Matrix.of(context).client.homeserver!.host,
                                maxLines: 1,
                              ),
                            ),
                          )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
