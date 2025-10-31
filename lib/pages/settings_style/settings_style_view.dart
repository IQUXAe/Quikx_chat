import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quikxchat/widgets/modern_back_button.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat/events/state_message.dart';
import 'package:quikxchat/utils/account_config.dart';
import 'package:quikxchat/utils/color_value.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/mxc_image.dart';
import '../../config/app_config.dart';
import '../../widgets/settings_card_tile.dart';
import 'settings_style.dart';

class SettingsStyleView extends StatelessWidget {
  final SettingsStyleController controller;

  const SettingsStyleView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const colorPickerSize = 32.0;
    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(
        leading: Center(child: ModernBackButton()),
        centerTitle: QuikxChatThemes.isColumnMode(context),
        title: Text(L10n.of(context).changeTheme),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: MaxWidthBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SegmentedButton<ThemeMode>(
                    selected: {controller.currentTheme},
                    onSelectionChanged: (selected) =>
                        controller.switchTheme(selected.single),
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(L10n.of(context).lightTheme),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(L10n.of(context).darkTheme),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(L10n.of(context).systemTheme),
                        icon: const Icon(Icons.auto_mode_outlined),
                      ),
                    ],
                  ),
                  if (controller.currentTheme == ThemeMode.dark || 
                      (controller.currentTheme == ThemeMode.system && 
                       Theme.of(context).brightness == Brightness.dark)) ...[
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('AMOLED'),
                      subtitle: const Text('Pure black background'),
                      value: controller.useAmoled,
                      onChanged: controller.setAmoled,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                L10n.of(context).setColorTheme,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DynamicColorBuilder(
              builder: (light, dark) {
                final systemColor =
                    Theme.of(context).brightness == Brightness.light
                        ? light?.primary
                        : dark?.primary;
                final colors =
                    List<Color?>.from(SettingsStyleController.customColors);
                if (systemColor == null) {
                  colors.remove(null);
                }
                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                  ),
                  itemCount: colors.length,
                  itemBuilder: (context, i) {
                    final color = colors[i];
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Tooltip(
                        message: color == null
                            ? L10n.of(context).systemTheme
                            : '#${color.hexValue.toRadixString(16).toUpperCase()}',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(colorPickerSize),
                          onTap: () => controller.setChatColor(color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color ?? systemColor,
                              borderRadius: BorderRadius.circular(colorPickerSize),
                              border: Border.all(
                                color: controller.currentColor == color
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                                width: controller.currentColor == color ? 3 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (color ?? systemColor ?? Colors.grey).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: controller.currentColor == color ? 2 : 0,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: colorPickerSize,
                              height: colorPickerSize,
                              child: controller.currentColor == color
                                  ? Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                L10n.of(context).messagesStyle,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder(
              stream: client.onSync.stream.where(
                (syncUpdate) =>
                    syncUpdate.accountData?.any(
                      (accountData) =>
                          accountData.type ==
                          ApplicationAccountConfigExtension.accountDataKey,
                    ) ??
                    false,
              ),
              builder: (context, snapshot) {
                final accountConfig = client.applicationAccountConfig;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: QuikxChatThemes.animationDuration,
                      curve: QuikxChatThemes.animationCurve,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (accountConfig.wallpaperUrl != null)
                            Opacity(
                              opacity: controller.wallpaperOpacity,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: controller.wallpaperBlur,
                                  sigmaY: controller.wallpaperBlur,
                                ),
                                child: MxcImage(
                                  key: ValueKey(accountConfig.wallpaperUrl),
                                  uri: accountConfig.wallpaperUrl,
                                  fit: BoxFit.cover,
                                  isThumbnail: true,
                                  width: QuikxChatThemes.columnWidth * 2,
                                  height: 212,
                                ),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.surface.withValues(alpha: accountConfig.wallpaperUrl != null ? 0.2 : 0.0),
                                  theme.colorScheme.surface.withValues(alpha: accountConfig.wallpaperUrl != null ? 0.85 : 0.0),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              StateMessage(
                                Event(
                                  eventId: 'style_dummy',
                                  room:
                                      Room(id: '!style_dummy', client: client),
                                  content: {'membership': 'join'},
                                  type: EventTypes.RoomMember,
                                  senderId: client.userID!,
                                  originServerTs: DateTime.now(),
                                  stateKey: client.userID!,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 12 + 12 + Avatar.defaultSize,
                                    right: 12,
                                    top: accountConfig.wallpaperUrl == null ? 0 : 12,
                                    bottom: 12,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.bubbleColor,
                                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Hi bro',
                                          style: TextStyle(
                                            color: theme.onBubbleColor,
                                            fontSize: AppConfig.messageFontSize * AppConfig.fontSizeFactor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '12:34',
                                          style: TextStyle(
                                            color: theme.onBubbleColor.withValues(alpha: 0.6),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: 12,
                                    left: 12,
                                    top: accountConfig.wallpaperUrl == null ? 0 : 12,
                                    bottom: 12,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Yo',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: AppConfig.messageFontSize * AppConfig.fontSizeFactor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '12:33',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text(
                        L10n.of(context).setWallpaper.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SettingsCardTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.wallpaper_outlined,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(L10n.of(context).setWallpaper),
                      trailing: accountConfig.wallpaperUrl == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outlined),
                              color: theme.colorScheme.error,
                              onPressed: controller.deleteChatWallpaper,
                            ),
                      onTap: controller.setWallpaper,
                      position: CardPosition.single,
                    ),
                    if (accountConfig.wallpaperUrl != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          L10n.of(context).opacity,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Slider.adaptive(
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        semanticFormatterCallback: (d) => d.toString(),
                        value: controller.wallpaperOpacity,
                        onChanged: controller.updateWallpaperOpacity,
                        onChangeEnd: controller.saveWallpaperOpacity,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          L10n.of(context).blur,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Slider.adaptive(
                        min: 0.0,
                        max: 10.0,
                        divisions: 10,
                        semanticFormatterCallback: (d) => d.toString(),
                        value: controller.wallpaperBlur,
                        onChanged: controller.updateWallpaperBlur,
                        onChangeEnd: controller.saveWallpaperBlur,
                      ),
                    ],
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L10n.of(context).fontSize,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text('× ${AppConfig.fontSizeFactor}'),
                ],
              ),
            ),
            Slider.adaptive(
              min: 0.5,
              max: 2.5,
              divisions: 20,
              value: AppConfig.fontSizeFactor,
              semanticFormatterCallback: (d) => d.toString(),
              onChanged: controller.changeFontSizeFactor,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                L10n.of(context).overview.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller.settingsNotifier,
              builder: (context, _, __) => Column(
                children: [
                  SettingsCardSwitch(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.visibility_outlined, color: Colors.green),
                    ),
                    title: Text(L10n.of(context).presencesToggle),
                    value: AppConfig.showPresences,
                    onChanged: (b) {
                      AppConfig.showPresences = b;
                      controller.settingsNotifier.value++;
                    },
                    position: CardPosition.first,
                  ),
                  SettingsCardSwitch(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.category_outlined, color: Colors.blue),
                    ),
                    title: Text(L10n.of(context).separateChatTypes),
                    value: AppConfig.separateChatTypes,
                    onChanged: (b) {
                      AppConfig.separateChatTypes = b;
                      controller.settingsNotifier.value++;
                    },
                    position: CardPosition.middle,
                  ),
                  SettingsCardSwitch(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.view_sidebar_outlined, color: Colors.purple),
                    ),
                    title: Text(L10n.of(context).displayNavigationRail),
                    value: AppConfig.displayNavigationRail,
                    onChanged: (b) {
                      AppConfig.displayNavigationRail = b;
                      controller.settingsNotifier.value++;
                    },
                    position: CardPosition.last,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
