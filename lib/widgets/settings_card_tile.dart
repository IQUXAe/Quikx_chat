import 'package:flutter/material.dart';
import 'package:quikxchat/widgets/tap_scale_animation.dart';

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

class _SettingsCardTileState extends State<SettingsCardTile> {

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
    
    return TapScaleAnimation(
      onTap: widget.onTap,
      child: Container(
        margin: _getMargin(),
        decoration: BoxDecoration(
          color: widget.isActive 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surface,
          borderRadius: _getBorderRadius(),
          border: Border.all(
            color: widget.isActive
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: widget.leading,
          title: DefaultTextStyle(
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            child: widget.title,
          ),
          subtitle: widget.subtitle,
          trailing: widget.trailing,
          onTap: null,
          shape: RoundedRectangleBorder(
            borderRadius: _getBorderRadius(),
          ),
        ),
      ),
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

class _SettingsCardSwitchState extends State<SettingsCardSwitch> {

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
    
    return TapScaleAnimation(
      onTap: widget.onChanged == null ? null : () => widget.onChanged!(!widget.value),
      child: Container(
        margin: _getMargin(),
        decoration: BoxDecoration(
          color: widget.isActive 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surface,
          borderRadius: _getBorderRadius(),
          border: Border.all(
            color: widget.isActive
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          secondary: widget.leading,
          title: DefaultTextStyle(
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            child: widget.title,
          ),
          subtitle: widget.subtitle,
          value: widget.value,
          onChanged: null,
          controlAffinity: ListTileControlAffinity.trailing,
          shape: RoundedRectangleBorder(
            borderRadius: _getBorderRadius(),
          ),
        ),
      ),
    );
  }
}