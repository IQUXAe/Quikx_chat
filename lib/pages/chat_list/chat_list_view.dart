import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:go_router/go_router.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/themes.dart';
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
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (controller.isSearchMode && controller.searchController.text.isEmpty) {
                  controller.cancelSearch(unfocus: false);
                }
              },
              excludeFromSemantics: true,
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                drawer: const AppDrawer(),
                body: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: RepaintBoundary(
                    child: ChatListViewBody(controller),
                  ),
                ),
                floatingActionButton: controller.scrollController.hasClients
                    ? _AnimatedFAB(
                        scrollController: controller.scrollController,
                        visible: !controller.isSearchMode && controller.activeSpaceId == null,
                        onPressed: () => context.go('/rooms/newprivatechat'),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFAB extends StatefulWidget {
  final ScrollController scrollController;
  final bool visible;
  final VoidCallback onPressed;

  const _AnimatedFAB({
    required this.scrollController,
    required this.visible,
    required this.onPressed,
  });

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isScrollingDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Increased duration for smoother animation
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Changed to elastic curve for more physics
      reverseCurve: Curves.elasticIn, // Reverse curve for more physics when hiding
    );
    widget.scrollController.addListener(_onScroll);
    if (widget.visible) _controller.forward();
  }

  void _onScroll() {
    if (widget.scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (!_isScrollingDown) {
        setState(() => _isScrollingDown = true);
        _controller.reverse();
      }
    } else if (widget.scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (_isScrollingDown) {
        setState(() => _isScrollingDown = false);
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(_AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible && !_isScrollingDown) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _scaleAnimation.value) * 20), // Add subtle vertical movement
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 6, // Increased elevation for more depth
              shape: RoundedRectangleBorder( // Add more physics-like shape
                borderRadius: BorderRadius.circular(16 + (4 * (1 - _scaleAnimation.value))),
              ),
              child: AnimatedScale(
                scale: 1.0 + (0.1 * (1 - _scaleAnimation.value)), // Slight scale effect on tap
                duration: const Duration(milliseconds: 100),
                child: const Icon(Icons.edit_outlined, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
