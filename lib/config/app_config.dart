import 'dart:ui';

import 'package:matrix/matrix.dart';

abstract class AppConfig {
  static String _applicationName = 'QuikxChat';

  static String get applicationName => _applicationName;
  static String? _applicationWelcomeMessage;

  static String? get applicationWelcomeMessage => _applicationWelcomeMessage;
  static String _defaultHomeserver = 'matrix.org';

  static String get defaultHomeserver => _defaultHomeserver;
  static double fontSizeFactor = 1;
  static const Color chatColor = primaryColor;
  static Color? colorSchemeSeed = primaryColor;
  static const double messageFontSize = 15.0;
  static const bool allowOtherHomeservers = true;
  static const bool enableRegistration = true;
  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color primaryColorLight = Color(0xFFDBEAFE);
  static const Color secondaryColor = Color(0xFF06B6D4);
  static String _privacyUrl = 'https://github.com/IQUXAe/Quikx_chat/blob/main/PRIVACY.md';

  static const Set<String> defaultReactions = {'👍', '❤️', '😂', '😮', '😢'};

  static String get privacyUrl => _privacyUrl;
  static const String website = 'https://github.com/IQUXAe/Quikx_chat';
  static const String enablePushTutorial = 'https://unifiedpush.org/users/distributors/';
  static const String encryptionTutorial = 'https://github.com/IQUXAe/Quikx_chat/wiki/Encryption';
  static const String startChatTutorial = 'https://github.com/IQUXAe/Quikx_chat/wiki/Getting-Started';
  static const String appId = 'com.iquxae.quikxchat';
  static const String appOpenUrlScheme = 'com.iquxae.quikxchat';
  static String _webBaseUrl = '';

  static String get webBaseUrl => _webBaseUrl;
  static const String sourceCodeUrl =
      'https://github.com/IQUXAe/Quikx_chat';
  static const String supportUrl =
      'https://github.com/IQUXAe/Quikx_chat/issues';
  // static const String changelogUrl =
  //     'https://github.com/IQUXAe/Quikx_chat/blob/main/CHANGELOG.md';

  static final Uri newIssueUrl = Uri(
    scheme: 'https',
    host: 'github.com',
    path: '/IQUXAe/Quikx_chat/issues/new',
  );
  static bool renderHtml = true;
  static bool hideRedactedEvents = false;
  static bool hideUnknownEvents = true;
  static bool separateChatTypes = false;
  static bool autoplayImages = true;
  static bool sendTypingNotifications = true;
  static bool sendPublicReadReceipts = true;
  static bool swipeRightToLeftToReply = true;
  static bool? sendOnEnter;
  static bool showPresences = false; // Disabled to reduce API calls
  static bool displayNavigationRail = false;
  static bool experimentalVoip = true; // Audio calls enabled by default, video calls remain experimental
  static bool showLinkPreviews = true;
  static bool forceDesktopMode = false;
  static const bool hideTypingUsernames = false;
  static const String inviteLinkPrefix = 'https://matrix.to/#/';
  static const String deepLinkPrefix = 'com.iquxae.quikxchat://chat/';
  static const String schemePrefix = 'matrix:';
  static const String pushNotificationsChannelId = 'quikxchat_push';
  static const String pushNotificationsAppId = 'com.iquxae.quikxchat';
  static const double borderRadius = 16.0;
  static const double columnWidth = 360.0;
  


  static final Uri homeserverList = Uri(
    scheme: 'https',
    host: 'servers.joinmatrix.org',
    path: 'servers.json',
  );

  static void loadFromJson(Map<String, dynamic> json) {
    if (json['chat_color'] != null) {
      try {
        colorSchemeSeed = Color(json['chat_color']);
      } catch (e) {
        Logs().w(
          'Invalid color in config.json! Please make sure to define the color in this format: "0xffdd0000"',
          e,
        );
      }
    }
    if (json['application_name'] is String) {
      _applicationName = json['application_name'];
    }
    if (json['application_welcome_message'] is String) {
      _applicationWelcomeMessage = json['application_welcome_message'];
    }
    if (json['default_homeserver'] is String) {
      _defaultHomeserver = json['default_homeserver'];
    }
    if (json['privacy_url'] is String) {
      _privacyUrl = json['privacy_url'];
    }
    if (json['web_base_url'] is String) {
      _webBaseUrl = json['web_base_url'];
    }
    if (json['render_html'] is bool) {
      renderHtml = json['render_html'];
    }
    if (json['hide_redacted_events'] is bool) {
      hideRedactedEvents = json['hide_redacted_events'];
    }
    if (json['hide_unknown_events'] is bool) {
      hideUnknownEvents = json['hide_unknown_events'];
    }

  }
}