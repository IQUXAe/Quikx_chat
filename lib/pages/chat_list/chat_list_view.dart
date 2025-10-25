import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat_list/chat_list.dart';
import 'package:quikxchat/widgets/app_drawer.dart';
import 'package:quikxchat/widgets/navigation_rail.dart';
import 'package:quikxchat/widgets/tap_scale_animation.dart';
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
                          child: TapScaleAnimation(
                            onTap: () => context.go('/rooms/newprivatechat'),
                            child: Container(
                              decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(Theme.of(context).colorScheme.primary, Colors.white, 0.1)!,
                                  Color.lerp(Theme.of(context).colorScheme.primary, Colors.black, 0.3)!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FloatingActionButton.extended(
                              onPressed: null,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              icon: const Icon(Icons.add_outlined),
                              label: Text(
                                L10n.of(context).chat,
                                overflow: TextOverflow.fade,
                              ),
                              heroTag: 'newChat',
                              ),
                            ),
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
