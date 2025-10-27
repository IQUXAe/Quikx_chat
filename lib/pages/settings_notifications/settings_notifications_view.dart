import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/settings_notifications/push_rule_extensions.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';
import '../../utils/localized_exception_extension.dart';
import '../../utils/notification_service.dart';
import '../../widgets/matrix.dart';
import 'settings_notifications.dart';

class SettingsNotificationsView extends StatelessWidget {
  final SettingsNotificationsController controller;

  const SettingsNotificationsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final pushRules = Matrix.of(context).client.globalPushRules;
    final pushCategories = [
      if (pushRules?.override?.isNotEmpty ?? false)
        (rules: pushRules?.override ?? [], kind: PushRuleKind.override),
      if (pushRules?.content?.isNotEmpty ?? false)
        (rules: pushRules?.content ?? [], kind: PushRuleKind.content),
      if (pushRules?.sender?.isNotEmpty ?? false)
        (rules: pushRules?.sender ?? [], kind: PushRuleKind.sender),
      if (pushRules?.underride?.isNotEmpty ?? false)
        (rules: pushRules?.underride ?? [], kind: PushRuleKind.underride),
    ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: QuikxChatThemes.isColumnMode(context),
        title: Text(L10n.of(context).notifications),
      ),
      body: MaxWidthBody(
        child: StreamBuilder(
          stream: Matrix.of(context).client.onSync.stream.where(
                (syncUpdate) =>
                    syncUpdate.accountData?.any(
                      (accountData) => accountData.type == 'm.push_rules',
                    ) ??
                    false,
              ),
          builder: (BuildContext context, _) {
            final theme = Theme.of(context);
            return SelectionArea(
              child: Column(
                children: [
                  if (pushRules != null)
                    for (final category in pushCategories) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: Text(
                          category.kind.localized(L10n.of(context)).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      for (var i = 0; i < category.rules.length; i++)
                        Builder(
                          builder: (context) {
                            final rule = category.rules[i];
                            final position = category.rules.length == 1 ? CardPosition.single :
                                           i == 0 ? CardPosition.first :
                                           i == category.rules.length - 1 ? CardPosition.last : CardPosition.middle;
                            return SettingsCardSwitch(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(rule.getPushRuleName(L10n.of(context))),
                              subtitle: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: rule.getPushRuleDescription(L10n.of(context)),
                                    ),
                                    const TextSpan(text: ' '),
                                    WidgetSpan(
                                      child: InkWell(
                                        onTap: () => controller.editPushRule(rule, category.kind),
                                        child: Text(
                                          L10n.of(context).more,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            decoration: TextDecoration.underline,
                                            decorationColor: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              value: rule.enabled,
                              onChanged: controller.isLoading
                                  ? null
                                  : rule.ruleId != '.m.rule.master' &&
                                          Matrix.of(context).client.allPushNotificationsMuted
                                      ? null
                                      : (_) => controller.togglePushRule(category.kind, rule),
                              position: position,
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],


                  FutureBuilder<PushNotificationStatus>(
                    future: NotificationService.instance.checkStatus(),
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? PushNotificationStatus.disabled;
                      String statusText;
                      Color? statusColor;
                      
                      switch (status) {
                        case PushNotificationStatus.enabled:
                          statusText = L10n.of(context).pushNotificationsEnabled;
                          statusColor = Colors.green;
                          break;
                        case PushNotificationStatus.disabled:
                          statusText = L10n.of(context).pushNotificationSetupRequired;
                          statusColor = Colors.grey;
                          break;
                        case PushNotificationStatus.permissionDenied:
                          statusText = L10n.of(context).pushNotificationPermissionDenied;
                          statusColor = Colors.red;
                          break;
                        case PushNotificationStatus.noDistributor:
                          statusText = L10n.of(context).noUnifiedPushDistributor;
                          statusColor = Colors.orange;
                          break;
                        case PushNotificationStatus.setupRequired:
                          statusText = L10n.of(context).pushNotificationSetupRequired;
                          statusColor = Colors.blue;
                          break;
                        case PushNotificationStatus.error:
                          statusText = L10n.of(context).pushNotificationError;
                          statusColor = Colors.red;
                          break;
                      }
                      
                      return SettingsCardTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: statusColor,
                          ),
                        ),
                        title: Text(L10n.of(context).pushNotificationStatus),
                        subtitle: Text(statusText),
                        position: CardPosition.first,
                      );
                    },
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications, color: Colors.blue),
                    ),
                    title: const Text('Test Push Notification'),
                    subtitle: const Text('Send a test notification to check if push notifications work'),
                    onTap: controller.testPushNotification,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info, color: Colors.orange),
                    ),
                    title: const Text('Debug Pushers'),
                    subtitle: const Text('Show pusher details in logs'),
                    onTap: controller.debugPushers,
                    position: CardPosition.middle,
                  ),
                  SettingsCardTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.settings, color: Colors.green),
                    ),
                    title: const Text('Setup UnifiedPush'),
                    subtitle: const Text('Reconfigure UnifiedPush and pusher'),
                    onTap: controller.isLoading ? null : controller.recreatePusher,
                    position: CardPosition.last,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      L10n.of(context).devices.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  FutureBuilder<List<Pusher>?>(
                    future: controller.pusherFuture ??=
                        Matrix.of(context).client.getPushers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            snapshot.error!.toLocalizedString(context),
                          ),
                        );
                      }
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        );
                      }
                      final pushers = snapshot.data ?? [];
                      if (pushers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(L10n.of(context).noOtherDevicesFound),
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: pushers.length,
                        itemBuilder: (_, i) => SettingsCardTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.devices_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            '${pushers[i].appDisplayName} - ${pushers[i].appId}',
                          ),
                          subtitle: Text(pushers[i].data.url.toString()),
                          onTap: () => controller.onPusherTap(pushers[i]),
                          position: pushers.length == 1 ? CardPosition.single : 
                                   i == 0 ? CardPosition.first :
                                   i == pushers.length - 1 ? CardPosition.last : CardPosition.middle,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
