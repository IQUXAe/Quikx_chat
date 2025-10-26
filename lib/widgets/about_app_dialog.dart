import 'package:flutter/material.dart';
import 'package:quikxchat/pages/settings/about_page.dart';
import 'package:quikxchat/config/themes.dart';

class AboutAppDialog {
  /// Показывает полноэкранную страницу "О проекте"
  static void show(BuildContext context) {
    if (QuikxChatThemes.isColumnMode(context)) {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (context) => Dialog.fullscreen(
          child: const AboutPage(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const AboutPage(),
        ),
      );
    }
  }
}