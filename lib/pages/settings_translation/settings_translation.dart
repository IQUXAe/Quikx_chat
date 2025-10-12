import 'package:flutter/material.dart';
import 'settings_translation_view.dart';

class SettingsTranslation extends StatefulWidget {
  const SettingsTranslation({super.key});

  @override
  SettingsTranslationController createState() => SettingsTranslationController();
}

class SettingsTranslationController extends State<SettingsTranslation> {
  @override
  Widget build(BuildContext context) => SettingsTranslationView(this);
}