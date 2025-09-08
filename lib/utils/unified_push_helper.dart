import 'dart:io';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush/unifiedpush.dart';

import 'package:simplemessenger/config/setting_keys.dart';
import 'package:simplemessenger/l10n/l10n.dart';

class UnifiedPushHelper {
  static const String instanceId = 'default';
  static const List<String> features = ['bytes_message'];
  
  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final distributors = await UnifiedPush.getDistributors(features);
      Logs().i('[UnifiedPush] Available distributors: $distributors');
      return distributors.isNotEmpty;
    } catch (e, s) {
      Logs().e('[UnifiedPush] Error checking availability', e, s);
      return false;
    }
  }

  static Future<bool> isConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool(SettingKeys.unifiedPushRegistered) ?? false;
      final hasEndpoint = prefs.getString(SettingKeys.unifiedPushEndpoint)?.isNotEmpty ?? false;
      final currentDistributor = await getCurrentDistributor();
      
      Logs().i('[UnifiedPush] Configuration check: registered=$isRegistered, hasEndpoint=$hasEndpoint, distributor=$currentDistributor');
      
      return isRegistered && hasEndpoint && currentDistributor != null;
    } catch (e, s) {
      Logs().e('[UnifiedPush] Error checking configuration', e, s);
      return false;
    }
  }

  static Future<String?> getCurrentDistributor() async {
    try {
      final distributor = await UnifiedPush.getDistributor();
      Logs().i('[UnifiedPush] Current distributor: $distributor');
      return distributor;
    } catch (e, s) {
      Logs().e('[UnifiedPush] Error getting current distributor', e, s);
      return null;
    }
  }

  static Future<List<String>> getAvailableDistributors() async {
    try {
      final distributors = await UnifiedPush.getDistributors(features);
      Logs().i('[UnifiedPush] Available distributors: $distributors');
      return distributors;
    } catch (e, s) {
      Logs().e('[UnifiedPush] Error getting distributors', e, s);
      return [];
    }
  }

  static Future<bool> setupWithDistributor(String distributor) async {
    try {
      Logs().i('[UnifiedPush] Setting up with distributor: $distributor');
      
      // Сначала сохраняем дистрибьютор
      await UnifiedPush.saveDistributor(distributor);
      Logs().i('[UnifiedPush] Distributor saved');
      
      // Затем регистрируемся
      await UnifiedPush.register(instance: instanceId, features: features);
      Logs().i('[UnifiedPush] Registration initiated');
      
      return true;
    } catch (e, s) {
      Logs().e('[UnifiedPush] Error setting up distributor', e, s);
      return false;
    }
  }
  
  static Future<void> unregister() async {
    try {
      Logs().i('[UnifiedPush] Unregistering');
      await UnifiedPush.unregister(instanceId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SettingKeys.unifiedPushRegistered, false);
      await prefs.remove(SettingKeys.unifiedPushEndpoint);
      
      Logs().i('[UnifiedPush] Unregistered successfully');
    } catch (e, s) {
      Logs().e('[UnifiedPush] Error during unregistration', e, s);
    }
  }

  static Future<void> showDistributorSelectionDialog(BuildContext context) async {
    final l10n = L10n.of(context);
    final distributors = await getAvailableDistributors();
    
    if (distributors.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.noUnifiedPushDistributor),
          content: Text(l10n.noUnifiedPushDistributorDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    final selectedDistributor = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select UnifiedPush Distributor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: distributors.map((distributor) {
            return ListTile(
              title: Text(distributor),
              onTap: () => Navigator.of(context).pop(distributor),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selectedDistributor != null) {
      final success = await setupWithDistributor(selectedDistributor);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'UnifiedPush configured with $selectedDistributor'
                : 'Failed to configure UnifiedPush',
            ),
          ),
        );
      }
    }
  }

  static Map<String, String> getDistributorInfo(String distributor) {
    // Информация о популярных дистрибьюторах UnifiedPush
    final distributorMap = {
      'org.unifiedpush.distributor.ntfy': {
        'name': 'ntfy',
        'description': 'Simple HTTP-based pub-sub notification service',
        'playStoreUrl': 'https://play.google.com/store/apps/details?id=io.heckel.ntfy',
        'fdroidUrl': 'https://f-droid.org/packages/io.heckel.ntfy/',
      },
      'org.unifiedpush.distributor.nextpush': {
        'name': 'NextPush',
        'description': 'UnifiedPush distributor for Nextcloud',
        'playStoreUrl': '',
        'fdroidUrl': 'https://f-droid.org/packages/org.unifiedpush.distributor.nextpush/',
      },
      'org.unifiedpush.distributor.gotify': {
        'name': 'Gotify',
        'description': 'Simple server for sending and receiving messages',
        'playStoreUrl': 'https://play.google.com/store/apps/details?id=com.github.gotify',
        'fdroidUrl': 'https://f-droid.org/packages/com.github.gotify/',
      },
    };

    return distributorMap[distributor] ?? {
      'name': distributor,
      'description': 'UnifiedPush distributor',
      'playStoreUrl': '',
      'fdroidUrl': '',
    };
  }
}