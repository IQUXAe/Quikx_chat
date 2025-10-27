import 'package:flutter/material.dart';

import 'matrix.dart';
import 'settings_card_tile.dart';

class SettingsSwitchListTile extends StatefulWidget {
  final bool defaultValue;
  final String storeKey;
  final String title;
  final String? subtitle;
  final Function(bool)? onChanged;

  const SettingsSwitchListTile.adaptive({
    super.key,
    this.defaultValue = false,
    required this.storeKey,
    required this.title,
    this.subtitle,
    this.onChanged,
  });

  @override
  SettingsSwitchListTileState createState() => SettingsSwitchListTileState();
}

class SettingsSwitchListTileState extends State<SettingsSwitchListTile> {
  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle;
    return SettingsCardSwitch(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.toggle_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(widget.title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: Matrix.of(context).store.getBool(widget.storeKey) ??
          widget.defaultValue,
      onChanged: (bool newValue) async {
        widget.onChanged?.call(newValue);
        await Matrix.of(context).store.setBool(widget.storeKey, newValue);
        setState(() {});
      },
    );
  }
}
