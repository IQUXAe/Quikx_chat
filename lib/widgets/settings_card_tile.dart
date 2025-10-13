import 'package:flutter/material.dart';

enum CardPosition { single, first, middle, last }

class SettingsCardTile extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isActive;
  final CardPosition position;

  const SettingsCardTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isActive = false,
    this.position = CardPosition.single,
  });

  @override
  State<SettingsCardTile> createState() => _SettingsCardTileState();
}

class _SettingsCardTileState extends State<SettingsCardTile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: _getMargin(),
            decoration: BoxDecoration(
              color: widget.isActive 
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: _getBorderRadius(),
            ),
            child: ListTile(
              leading: widget.leading,
              title: widget.title,
              subtitle: widget.subtitle,
              trailing: widget.trailing,
              onTap: widget.onTap == null ? null : () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                widget.onTap!();
              },
              shape: RoundedRectangleBorder(
                borderRadius: _getBorderRadius(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsCardSwitch extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isActive;
  final CardPosition position;

  const SettingsCardSwitch({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.isActive = false,
    this.position = CardPosition.single,
  });

  @override
  State<SettingsCardSwitch> createState() => _SettingsCardSwitchState();
}

class _SettingsCardSwitchState extends State<SettingsCardSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: _getMargin(),
            decoration: BoxDecoration(
              color: widget.isActive 
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: _getBorderRadius(),
            ),
            child: SwitchListTile.adaptive(
              secondary: widget.leading,
              title: widget.title,
              subtitle: widget.subtitle,
              value: widget.value,
              onChanged: widget.onChanged == null ? null : (value) {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                widget.onChanged!(value);
              },
              controlAffinity: ListTileControlAffinity.trailing,
              shape: RoundedRectangleBorder(
                borderRadius: _getBorderRadius(),
              ),
            ),
          ),
        );
      },
    );
  }
}