import 'package:flutter/material.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';

class DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool closeDrawer;
  final CardPosition position;
  final Animation<double> animation;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.closeDrawer = true,
    required this.position,
    required this.animation,
  });

  @override
  State<DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<DrawerMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (1 - widget.animation.value) * -30,
            0,
          ),
          child: Opacity(
            opacity: widget.animation.value.clamp(0.0, 1.0),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: _getMargin(),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: _getBorderRadius(),
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
                        borderRadius: _getBorderRadius(),
                        onTapDown: (_) => _controller.forward(),
                        onTapUp: (_) {
                          _controller.reverse();
                          if (widget.closeDrawer) {
                            Navigator.of(context).pop();
                          }
                          widget.onTap();
                        },
                        onTapCancel: () => _controller.reverse(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (widget.iconColor ?? Colors.grey)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.iconColor ?? Colors.grey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getMargin() {
    switch (widget.position) {
      case CardPosition.single:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 4);
      case CardPosition.first:
        return const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 1);
      case CardPosition.middle:
        return const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 1);
      case CardPosition.last:
        return const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 4);
    }
  }
  
  BorderRadius _getBorderRadius() {
    switch (widget.position) {
      case CardPosition.single:
        return BorderRadius.circular(12);
      case CardPosition.first:
        return const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        );
      case CardPosition.middle:
        return BorderRadius.zero;
      case CardPosition.last:
        return const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        );
    }
  }
}