import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


import '../config/app_config.dart';
import '../config/app_version.dart';
import '../widgets/about_app_dialog.dart';

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

  /// Media kit availability status (set at startup)
  static bool mediaKitAvailable = false;

  /// Web could also record in theory but currently only wav which is too large
  static bool get platformCanRecord => isMobile || (isLinux && mediaKitAvailable);
  
  /// Audio playback support
  static bool get supportsAudioPlayback => isMobile || (isLinux && mediaKitAvailable);

  static String get clientName =>
      '${AppConfig.applicationName} ${isWeb ? 'web' : Platform.operatingSystem}${kReleaseMode ? '' : 'Debug'}';

  static Future<String> getVersion() async {
    return AppVersion.version;
  }

  static void showAboutDialog(BuildContext context) {
    AboutAppDialog.show(context);
  }
}
