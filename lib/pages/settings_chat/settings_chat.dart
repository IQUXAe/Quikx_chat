import 'package:flutter/material.dart';

import 'settings_chat_view.dart';

class SettingsChat extends StatefulWidget {
  const SettingsChat({super.key});

  @override
  SettingsChatController createState() => SettingsChatController();
}

class SettingsChatController extends State<SettingsChat> {
  final settingsNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) => SettingsChatView(this);
}
