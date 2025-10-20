import 'package:flutter/material.dart';
import 'settings_card_tile.dart';

class SettingsCardGroup extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final EdgeInsets? padding;

  const SettingsCardGroup({
    super.key,
    required this.children,
    this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ...children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          
          if (child is SettingsCardTile) {
            final position = children.length == 1 
                ? CardPosition.single
                : index == 0 
                    ? CardPosition.first
                    : index == children.length - 1 
                        ? CardPosition.last 
                        : CardPosition.middle;
            
            return SettingsCardTile(
              leading: child.leading,
              title: child.title,
              subtitle: child.subtitle,
              trailing: child.trailing,
              onTap: child.onTap,
              isActive: child.isActive,
              position: position,
            );
          } else if (child is SettingsCardSwitch) {
            final position = children.length == 1 
                ? CardPosition.single
                : index == 0 
                    ? CardPosition.first
                    : index == children.length - 1 
                        ? CardPosition.last 
                        : CardPosition.middle;
            
            return SettingsCardSwitch(
              leading: child.leading,
              title: child.title,
              subtitle: child.subtitle,
              value: child.value,
              onChanged: child.onChanged,
              isActive: child.isActive,
              position: position,
            );
          }
          
          return child;
        }),
      ],
    );
  }
}