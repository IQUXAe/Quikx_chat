import 'package:flutter/material.dart';

enum CardPosition { single, first, middle, last }

class SettingsCardTile extends StatelessWidget {
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

  BorderRadius _getBorderRadius() {
    switch (position) {
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
    switch (position) {
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
    
    return Container(
      margin: _getMargin(),
      decoration: BoxDecoration(
        color: isActive 
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: _getBorderRadius(),
      ),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: _getBorderRadius(),
        ),
      ),
    );
  }
}

class SettingsCardSwitch extends StatelessWidget {
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

  BorderRadius _getBorderRadius() {
    switch (position) {
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
    switch (position) {
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
    
    return Container(
      margin: _getMargin(),
      decoration: BoxDecoration(
        color: isActive 
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: _getBorderRadius(),
      ),
      child: SwitchListTile.adaptive(
        secondary: leading,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(
          borderRadius: _getBorderRadius(),
        ),
      ),
    );
  }
}