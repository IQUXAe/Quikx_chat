import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/matrix.dart';
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Text(
                  L10n.of(context).chat.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.format_bold_outlined, color: Colors.blue),
                  ),
                  title: Text(L10n.of(context).formattedMessages),
                  subtitle: Text(L10n.of(context).formattedMessagesDescription),
                  value: AppConfig.renderHtml,
                  onChanged: (b) {
                    AppConfig.renderHtml = b;
                    widget.controller.settingsNotifier.value++;
                  },
                  position: CardPosition.first,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility_off_outlined, color: Colors.red),
                  ),
                  title: Text(L10n.of(context).hideRedactedMessages),
                  subtitle: Text(L10n.of(context).hideRedactedMessagesBody),
                  value: AppConfig.hideRedactedEvents,
                  onChanged: (b) {
                    AppConfig.hideRedactedEvents = b;
                    widget.controller.settingsNotifier.value++;
                  },
                  position: CardPosition.middle,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.block_outlined, color: Colors.orange),
                  ),
                  title: Text(L10n.of(context).hideInvalidOrUnknownMessageFormats),
                  value: AppConfig.hideUnknownEvents,
                  onChanged: (b) {
                    AppConfig.hideUnknownEvents = b;
                    widget.controller.settingsNotifier.value++;
                  },
                  position: PlatformInfos.isMobile ? CardPosition.middle : CardPosition.middle,
                ),
              ),
              if (PlatformInfos.isMobile)
                ValueListenableBuilder(
                  valueListenable: widget.controller.settingsNotifier,
                  builder: (context, _, __) => SettingsCardSwitch(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_outlined, color: Colors.purple),
                    ),
                    title: Text(L10n.of(context).autoplayImages),
                    value: AppConfig.autoplayImages,
                    onChanged: (b) {
                      AppConfig.autoplayImages = b;
                      widget.controller.settingsNotifier.value++;
                    },
                    position: CardPosition.middle,
                  ),
                ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.keyboard_return_outlined, color: Colors.green),
                  ),
                  title: Text(L10n.of(context).sendOnEnter),
                  value: AppConfig.sendOnEnter ?? !PlatformInfos.isMobile,
                  onChanged: (b) {
                    AppConfig.sendOnEnter = b;
                    widget.controller.settingsNotifier.value++;
                  },
                  position: CardPosition.middle,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swipe_outlined, color: Colors.teal),
                  ),
                  title: Text(L10n.of(context).swipeRightToLeftToReply),
                  value: AppConfig.swipeRightToLeftToReply,
                  onChanged: (b) {
                    AppConfig.swipeRightToLeftToReply = b;
                    widget.controller.settingsNotifier.value++;
                  },
                  position: CardPosition.middle,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link_outlined, color: Colors.indigo),
                  ),
                  title: Text(L10n.of(context).linkPreviews),
                  subtitle: Text(L10n.of(context).linkPreviewsDescription),
                  value: AppSettings.showLinkPreviews.getItem(Matrix.of(context).store),
                  onChanged: (b) async {
                    AppConfig.showLinkPreviews = b;
                    await AppSettings.showLinkPreviews.setItem(Matrix.of(context).store, b);
                    widget.controller.settingsNotifier.value++;
                  },
                  position: CardPosition.middle,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller.settingsNotifier,
                builder: (context, _, __) => SettingsCardSwitch(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time_outlined, color: Colors.cyan),
                  ),
                  title: Text(L10n.of(context).use24HourTimeFormat),
                  subtitle: Text(L10n.of(context).use24HourTimeFormatDescription),
                  value: true,
                  onChanged: (b) {
                    Matrix.of(context).store.setBool('use24HourFormat', b);
                    widget.controller.settingsNotifier.value++;
                  },
                  position: CardPosition.last,
                ),
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
                        color: isEnabled ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
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
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.purple,),
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
