import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:quikxchat/l10n/l10n.dart';
import '../config/app_config.dart';

abstract class PlatformInfos {
  static bool get isWeb => kIsWeb;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isCupertinoStyle => false;

  static bool get isMobile => isAndroid;

  /// For desktops which don't support ChachedNetworkImage yet
  static bool get isBetaDesktop => isWindows || isLinux;

  static bool get isDesktop => isLinux || isWindows;

  static bool get usesTouchscreen => !isMobile;

  static bool get supportsVideoPlayer =>
      !PlatformInfos.isWindows && !PlatformInfos.isLinux;

  /// Web could also record in theory but currently only wav which is too large
  static bool get platformCanRecord => isMobile;

  static String get clientName =>
      '${AppConfig.applicationName} ${isWeb ? 'web' : Platform.operatingSystem}${kReleaseMode ? '' : 'Debug'}';

  static Future<String> getVersion() async {
    var version = kIsWeb ? 'Web' : 'Unknown';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return version;
  }

  static void showAboutDialog(BuildContext context) async {
    final version = await PlatformInfos.getVersion();
    showDialog<void>(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConfig.applicationName,
        applicationVersion: version,
        applicationIcon: Image.asset('assets/logo.png', width: 64, height: 64),
        children: [
          const Text('Безопасный мессенджер на основе протокола Matrix.'),
          const SizedBox(height: 16),
          const Text('Разработчик: IQUXAe'),
          const SizedBox(height: 8),
          const Text('Создан с помощью Flutter и Matrix SDK'),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => launchUrlString(AppConfig.sourceCodeUrl),
            icon: const Icon(Icons.code_outlined),
            label: Text(L10n.of(context).sourceCode),
          ),
        ],
      ),
    );
  }
}
