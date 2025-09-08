import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:simplemessenger/config/app_config.dart';
import 'package:simplemessenger/config/setting_keys.dart';
import 'package:simplemessenger/config/themes.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/utils/platform_infos.dart';
import 'package:simplemessenger/widgets/layouts/max_width_body.dart';
import 'package:simplemessenger/widgets/matrix.dart';
import 'package:simplemessenger/widgets/settings_switch_list_tile.dart';
import '../../utils/message_translator.dart';
import 'settings_chat.dart';

class SettingsChatView extends StatelessWidget {
  final SettingsChatController controller;
  const SettingsChatView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).chat),
        automaticallyImplyLeading: !SimpleMessengerThemes.isColumnMode(context),
        centerTitle: SimpleMessengerThemes.isColumnMode(context),
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
                title: L10n.of(context).use24HourTimeFormat,
                subtitle: L10n.of(context).use24HourTimeFormatDescription,
                onChanged: (b) => Matrix.of(context).store.setBool('use24HourFormat', b),
                storeKey: 'use24HourFormat',
                defaultValue: true,
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return FutureBuilder<bool>(
                    future: MessageTranslator.isEnabled,
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return SwitchListTile.adaptive(
                        controlAffinity: ListTileControlAffinity.trailing,
                        value: isEnabled,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.translate, color: Colors.lightBlue),
                        ),
                        title: Text(L10n.of(context).messageTranslation),
                        subtitle: Text(L10n.of(context).messageTranslationDescription),
                        onChanged: (value) async {
                          await MessageTranslator.setEnabled(value);
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return FutureBuilder<String>(
                    future: MessageTranslator.targetLanguage,
                    builder: (context, snapshot) {
                      final targetLang = snapshot.data ?? 'auto';
                      final languages = {
                        'auto': L10n.of(context).systemLanguage,
                        'en': 'English',
                        'ru': 'Русский',
                        'es': 'Español',
                        'fr': 'Français',
                        'de': 'Deutsch',
                        'it': 'Italiano',
                        'pt': 'Português',
                        'zh': '中文',
                        'ja': '日本語',
                        'ko': '한국어',
                      };
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.language, color: Colors.green),
                        ),
                        title: Text(L10n.of(context).targetLanguage),
                        subtitle: Text(languages[targetLang] ?? targetLang),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          final selected = await showDialog<String>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: Text(L10n.of(context).selectTargetLanguage),
                              children: languages.entries.map((entry) => 
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(context, entry.key),
                                  child: Text(entry.value),
                                ),
                              ).toList(),
                            ),
                          );
                          if (selected != null) {
                            await MessageTranslator.setTargetLanguage(selected);
                            setState(() {});
                          }
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Divider(color: theme.dividerColor),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_emotions_outlined, color: Colors.purple),
                ),
                title: Text(L10n.of(context).personalEmojis),
                subtitle: Text(L10n.of(context).personalEmojisDescription),
                onTap: () => context.go('/rooms/settings/chat/emotes'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
