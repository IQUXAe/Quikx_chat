import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/app_version.dart';
import 'package:quikxchat/l10n/l10n.dart';

class DrawerDialogs {
  static void showUpdateDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).updateAvailable),
        content: Text('${L10n.of(context).newVersionAvailable(data['latest_version'])}\\n\\n${data['release_notes'] ?? ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).later),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (data['download_url'] != null) {
                launchUrl(Uri.parse(data['download_url']));
              }
            },
            child: Text(L10n.of(context).update),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  static void showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).noUpdates),
        content: Text(L10n.of(context).latestVersion(AppVersion.version)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  static void showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).oopsSomethingWentWrong),
        content: Text(L10n.of(context).errorCheckingUpdates),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  static void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConfig.applicationName,
        applicationVersion: AppVersion.version,
        applicationIcon: Image.asset('assets/logo.png', width: 64, height: 64),
        children: [
          Text(L10n.of(context).simpleSecureMessaging),
          const SizedBox(height: 16),
          Text(L10n.of(context).developerIquxae),
          const SizedBox(height: 8),
          Text(L10n.of(context).builtWithFlutter),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }
}