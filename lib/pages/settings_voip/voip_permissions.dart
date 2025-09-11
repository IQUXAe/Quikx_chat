import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VoipPermissionsHelper {
  static Future<bool> checkAllPermissions() async {
    if (kIsWeb) return true;
    
    final permissions = await _getRequiredPermissions();
    final statuses = await permissions.request();
    
    return statuses.values.every((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited,);
  }

  static Future<Map<Permission, PermissionStatus>> getPermissionStatuses() async {
    if (kIsWeb) return {};
    
    final permissions = await _getRequiredPermissions();
    final statuses = <Permission, PermissionStatus>{};
    
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }
    
    return statuses;
  }

  static Future<List<Permission>> _getRequiredPermissions() async {
    final permissions = <Permission>[
      Permission.microphone,
      Permission.camera,
    ];
    
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.phone,
        Permission.systemAlertWindow,
      ]);
    }
    
    return permissions;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    
    final permissions = await _getRequiredPermissions();
    final statuses = await permissions.request();
    
    return statuses.values.every((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited,);
  }

  static String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Микрофон';
      case Permission.camera:
        return 'Камера';
      case Permission.phone:
        return 'Телефон';
      case Permission.systemAlertWindow:
        return 'Поверх других приложений';
      default:
        return permission.toString();
    }
  }

  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Необходимо для голосовых звонков';
      case Permission.camera:
        return 'Необходимо для видео звонков';
      case Permission.phone:
        return 'Необходимо для управления звонками';
      case Permission.systemAlertWindow:
        return 'Необходимо для отображения входящих звонков';
      default:
        return 'Необходимо для работы VoIP';
    }
  }

  static IconData getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return Icons.mic;
      case Permission.camera:
        return Icons.videocam;
      case Permission.phone:
        return Icons.phone;
      case Permission.systemAlertWindow:
        return Icons.layers;
      default:
        return Icons.security;
    }
  }
}