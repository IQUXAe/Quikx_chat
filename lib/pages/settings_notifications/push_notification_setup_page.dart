import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/push_notification_manager.dart';
import 'package:quikxchat/utils/unified_push_helper.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/matrix.dart';

class PushNotificationSetupPage extends StatefulWidget {
  const PushNotificationSetupPage({super.key});

  @override
  State<PushNotificationSetupPage> createState() =>
      _PushNotificationSetupPageState();
}

class _PushNotificationSetupPageState extends State<PushNotificationSetupPage> {
  PushNotificationStatus _status = PushNotificationStatus.disabled;
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _loadDiagnostics();
  }

  Future<void> _checkStatus() async {
    final status = await PushNotificationManager.instance.checkStatus();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  Future<void> _loadDiagnostics() async {
    final diagnostics =
        await PushNotificationManager.instance.getDiagnosticInfo();
    if (mounted) {
      setState(() {
        _diagnostics = diagnostics;
      });
    }
  }

  Future<void> _setupAutomatically() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matrix = Matrix.of(context);
      final success = await PushNotificationManager.instance
          .setupAutomatically(context, matrix);

      if (success) {
        await _checkStatus();
        await _loadDiagnostics();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSetupDialog() async {
    final matrix = Matrix.of(context);
    await PushNotificationManager.instance.showSetupDialog(context, matrix);
    await _checkStatus();
    await _loadDiagnostics();
  }

  Future<void> _copyDiagnostics() async {
    if (_diagnostics == null) return;

    final diagnosticsText =
        const JsonEncoder.withIndent('  ').convert(_diagnostics);
    await Clipboard.setData(ClipboardData(text: diagnosticsText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).diagnosticsCopied)),
      );
    }
  }

  Widget _buildStatusCard() {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (_status) {
      case PushNotificationStatus.enabled:
        icon = Icons.check_circle;
        color = Colors.green;
        title = l10n.pushNotificationsEnabled;
        subtitle = l10n.pushNotificationsEnabled;
        break;
      case PushNotificationStatus.disabled:
        icon = Icons.notifications_off;
        color = Colors.grey;
        title = l10n.pushNotifications;
        subtitle = l10n.configurePushNotifications;
        break;
      case PushNotificationStatus.permissionDenied:
        icon = Icons.block;
        color = Colors.red;
        title = l10n.pushNotificationPermissionDenied;
        subtitle = l10n.pushNotificationPermissionDescription;
        break;
      case PushNotificationStatus.noDistributor:
        icon = Icons.warning;
        color = Colors.orange;
        title = l10n.noUnifiedPushDistributor;
        subtitle = l10n.noUnifiedPushDistributorDescription;
        break;
      case PushNotificationStatus.setupRequired:
        icon = Icons.settings;
        color = Colors.blue;
        title = l10n.pushNotificationSetupRequired;
        subtitle = l10n.configurePushNotifications;
        break;
      case PushNotificationStatus.error:
        icon = Icons.error;
        color = Colors.red;
        title = l10n.pushNotificationError;
        subtitle = l10n.pushNotificationError;
        break;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: _status != PushNotificationStatus.enabled
            ? ElevatedButton(
                onPressed: _isLoading ? null : _setupAutomatically,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.setupNow),
              )
            : null,
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = L10n.of(context);

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showSetupDialog,
                icon: const Icon(Icons.settings),
                label: Text(l10n.manualSetupPushNotifications),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _testNotifications,
                icon: const Icon(Icons.notifications_active),
                label: Text(l10n.testPushNotifications),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyDiagnostics,
            icon: const Icon(Icons.bug_report),
            label: Text(l10n.pushNotificationDiagnostics),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetPushSettings,
            icon: const Icon(
                Icons.refresh), // TODO: Localize 'Reset push settings'
            label: Text(L10n.of(context).settings), // Or a more specific key
          ),
        ),
      ],
    );
  }

  Future<void> _testNotifications() async {
    try {
      // Отправляем тестовое уведомление
      await PushNotificationManager.instance.localNotifications.show(
        999,
        L10n.of(context).testPushNotifications,
        L10n.of(context)
            .pushNotificationTestSent, // A more descriptive message could be added to l10n
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).pushNotificationTestSent)),
        );
      }
    } catch (e) {
      Logs().e('Failed to send test notification', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L10n.of(context).error}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _openSystemSettings() async {
    if (Platform.isAndroid) {
      await openAppSettings();
    }
  }

  Future<void> _installDistributor(String distributorName) async {
    var url = '';

    switch (distributorName.toLowerCase()) {
      case 'ntfy':
        url = 'https://play.google.com/store/apps/details?id=io.heckel.ntfy';
        break;
      case 'nextpush':
        url =
            'https://f-droid.org/packages/org.unifiedpush.distributor.nextpush/';
        break;
      case 'gotify':
        url = 'https://play.google.com/store/apps/details?id=com.github.gotify';
        break;
    }

    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _resetPushSettings() async {
    final l10n = L10n.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).settings), // Or a more specific key
        content: Text(L10n.of(context).areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(true), // TODO: Localize 'Reset'
            child: Text(L10n.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await UnifiedPushHelper.unregister();
        await _checkStatus();
        await _loadDiagnostics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.of(context).settingsSaved)),
          );
        }
      } catch (e) {
        Logs().e('Failed to reset push settings', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${L10n.of(context).error}: $e')),
          );
        }
      }
    }
  }

  Widget _buildDistributorCard() {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.of(context).discoverHomeservers, // Or a more specific key
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDistributorTile('ntfy',
                'ntfy - простой HTTP-сервис для pub-sub уведомлений'), // TODO: Localize
            _buildDistributorTile('NextPush',
                'NextPush - дистрибьютор UnifiedPush для Nextcloud'), // TODO: Localize
            _buildDistributorTile('Gotify',
                'Gotify - простой сервер для отправки и получения сообщений'), // TODO: Localize
          ],
        ),
      ),
    );
  }

  Widget _buildDistributorTile(String name, String description) {
    return ListTile(
      title: Text(name),
      subtitle: Text(description),
      trailing: OutlinedButton(
        onPressed: () => _installDistributor(name),
        child: Text(L10n.of(context).start), // Or 'Install'
      ),
    );
  }

  Widget _buildDiagnosticsCard() {
    if (_diagnostics == null) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.diagnostics),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in _diagnostics!.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${entry.key}:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value?.toString() ?? 'null',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copyDiagnostics,
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.copyDiagnostics),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Устранение неполадок',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('1. Проверьте разрешения на уведомления'),
            const SizedBox(height: 8),
            const Text(
                '2. Убедитесь, что дистрибьютор UnifiedPush установлен и работает'),
            const SizedBox(height: 8),
            const Text('3. Перезапустите приложение'),
            const SizedBox(height: 8),
            const Text('4. Отключите оптимизацию батареи для приложения'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openSystemSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Открыть системные настройки'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedCard() {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Расширенные настройки',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(l10n.unifiedPushDescription),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://unifiedpush.org/users/distributors/');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Открыть документацию'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'https://github.com/iquxae/simple-messenger/issues/new');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Создать issue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pushNotifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _checkStatus();
              await _loadDiagnostics();
            },
          ),
        ],
      ),
      body: MaxWidthBody(
        child: RefreshIndicator(
          onRefresh: () async {
            await _checkStatus();
            await _loadDiagnostics();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildDistributorCard(),
              const SizedBox(height: 16),
              _buildDiagnosticsCard(),
              const SizedBox(height: 16),
              _buildTroubleshootingCard(),
              const SizedBox(height: 16),
              _buildAdvancedCard(),
            ],
          ),
        ),
      ),
    );
  }
}
