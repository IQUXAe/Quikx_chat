import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat_list/chat_list.dart';
import 'package:quikxchat/widgets/app_drawer.dart';
import 'package:quikxchat/widgets/navigation_rail.dart';
import 'chat_list_body.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !controller.isSearchMode && controller.activeSpaceId == null,
      onPopInvokedWithResult: (pop, _) {
        if (pop) return;
        if (controller.activeSpaceId != null) {
          controller.clearActiveSpace();
          return;
        }
        if (controller.isSearchMode) {
          controller.cancelSearch();
          return;
        }
      },
      child: Row(
        children: [
          if (QuikxChatThemes.isColumnMode(context) ||
              AppConfig.displayNavigationRail) ...[
            SpacesNavigationRail(
              activeSpaceId: controller.activeSpaceId,
              onGoToChats: controller.clearActiveSpace,
              onGoToSpaceId: controller.setActiveSpace,
            ),
            Container(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ],
          Expanded(
            child: GestureDetector(
              onTap: FocusManager.instance.primaryFocus?.unfocus,
              excludeFromSemantics: true,
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                drawer: const AppDrawer(),
                body: RepaintBoundary(
                  child: ChatListViewBody(controller),
                ),
                floatingActionButton: AnimatedSwitcher(
                  duration: QuikxChatThemes.animationDuration,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: !controller.isSearchMode &&
                          controller.activeSpaceId == null
                      ? RepaintBoundary(
                          child: FloatingActionButton.extended(
                            onPressed: () => context.go('/rooms/newprivatechat'),
                            icon: const Icon(Icons.add_outlined),
                            label: Text(
                              L10n.of(context).chat,
                              overflow: TextOverflow.fade,
                            ),
                            heroTag: 'newChat',
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
