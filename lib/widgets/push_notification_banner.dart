import 'package:flutter/material.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/notification_service.dart';
import 'package:quikxchat/widgets/matrix.dart';

class PushNotificationBanner extends StatefulWidget {
  const PushNotificationBanner({super.key});

  @override
  State<PushNotificationBanner> createState() => _PushNotificationBannerState();
}

class _PushNotificationBannerState extends State<PushNotificationBanner> {
  PushNotificationStatus _status = PushNotificationStatus.disabled;
  bool _isDismissed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await NotificationService.instance.checkStatus();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  Future<void> _setupNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matrix = Matrix.of(context);
      final success = await NotificationService.instance.setupAutomatically(context, matrix);
      
      if (success) {
        setState(() {
          _isDismissed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _dismiss() {
    setState(() {
      _isDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Не показываем баннер если уведомления уже настроены или баннер был закрыт
    if (_status == PushNotificationStatus.enabled || _isDismissed) {
      return const SizedBox.shrink();
    }

    final l10n = L10n.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.configurePushNotifications,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pushNotificationSetupDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _dismiss,
                    child: Text(
                      l10n.later,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _setupNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.setupNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}