import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/settings_switch_list_tile.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';

import '../../utils/translation_providers.dart';
import 'settings_chat.dart';

class SettingsChatView extends StatefulWidget {
  final SettingsChatController controller;
  const SettingsChatView(this.controller, {super.key});

  @override
  State<SettingsChatView> createState() => _SettingsChatViewState();
}

class _SettingsChatViewState extends State<SettingsChatView> {
  TranslationProvider? _currentProvider;

  @override
  void initState() {
    super.initState();
    _loadTranslationProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTranslationProvider();
  }

  void _loadTranslationProvider() async {
    final provider = await TranslationProviders.getCurrentProvider();
    if (mounted) {
      setState(() {
        _currentProvider = provider;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(L10n.of(context).chat),
        centerTitle: QuikxChatThemes.isColumnMode(context),
      ),
      body: ListTileTheme(
        iconColor: theme.textTheme.bodyLarge!.color,
        child: MaxWidthBody(
          child: Column(
            children: [
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).formattedMessages,
                subtitle: L10n.of(context).formattedMessagesDescription,
                onChanged: (b) => AppConfig.renderHtml = b,
                storeKey: SettingKeys.renderHtml,
                defaultValue: AppConfig.renderHtml,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).hideRedactedMessages,
                subtitle: L10n.of(context).hideRedactedMessagesBody,
                onChanged: (b) => AppConfig.hideRedactedEvents = b,
                storeKey: SettingKeys.hideRedactedEvents,
                defaultValue: AppConfig.hideRedactedEvents,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).hideInvalidOrUnknownMessageFormats,
                onChanged: (b) => AppConfig.hideUnknownEvents = b,
                storeKey: SettingKeys.hideUnknownEvents,
                defaultValue: AppConfig.hideUnknownEvents,
              ),
              if (PlatformInfos.isMobile)
                SettingsSwitchListTile.adaptive(
                  title: L10n.of(context).autoplayImages,
                  onChanged: (b) => AppConfig.autoplayImages = b,
                  storeKey: SettingKeys.autoplayImages,
                  defaultValue: AppConfig.autoplayImages,
                ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).sendOnEnter,
                onChanged: (b) => AppConfig.sendOnEnter = b,
                storeKey: SettingKeys.sendOnEnter,
                defaultValue: AppConfig.sendOnEnter ?? !PlatformInfos.isMobile,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).swipeRightToLeftToReply,
                onChanged: (b) => AppConfig.swipeRightToLeftToReply = b,
                storeKey: SettingKeys.swipeRightToLeftToReply,
                defaultValue: AppConfig.swipeRightToLeftToReply,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).linkPreviews,
                subtitle: L10n.of(context).linkPreviewsDescription,
                onChanged: (b) async {
                  AppConfig.showLinkPreviews = b;
                  await AppSettings.showLinkPreviews.setItem(Matrix.of(context).store, b);
                },
                storeKey: SettingKeys.showLinkPreviews,
                defaultValue: AppSettings.showLinkPreviews.getItem(Matrix.of(context).store),
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).use24HourTimeFormat,
                subtitle: L10n.of(context).use24HourTimeFormatDescription,
                onChanged: (b) =>
                    Matrix.of(context).store.setBool('use24HourFormat', b),
                storeKey: 'use24HourFormat',
                defaultValue: true,
              ),

              
              const SizedBox(height: 16),
              
              // Дополнительные настройки
              Builder(
                builder: (context) {
                  final provider = _currentProvider ?? TranslationProvider.disabled;
                  final isEnabled = provider != TranslationProvider.disabled;
                  
                  return SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.translate,
                        color: isEnabled ? Colors.blue : Colors.grey,
                      ),
                    ),
                    title: const Text('Translation Settings (Beta)'),
                    subtitle: Text(
                      isEnabled ? 'Translation enabled' : 'Translation disabled',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await context.push('/rooms/settings/chat/translation');
                      _loadTranslationProvider();
                    },
                    position: CardPosition.first,
                  );
                },
              ),
              SettingsCardTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.purple),
                ),
                title: Text(L10n.of(context).personalEmojis),
                subtitle: Text(L10n.of(context).personalEmojisDescription),
                onTap: () => context.go('/rooms/settings/chat/emotes'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                position: CardPosition.last,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
