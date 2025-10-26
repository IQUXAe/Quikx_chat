#!/usr/bin/env dart

import 'dart:io';

void main() {
  // Читаем версию из app_version.dart
  final appVersionFile = File('lib/config/app_version.dart');
  if (!appVersionFile.existsSync()) {
    print('Ошибка: файл lib/config/app_version.dart не найден');
    exit(1);
  }

  final content = appVersionFile.readAsStringSync();
  final versionMatch = RegExp(r"static const String version = '([^']+)';").firstMatch(content);
  final buildMatch = RegExp(r"static const String buildNumber = '([^']+)';").firstMatch(content);
  
  if (versionMatch == null || buildMatch == null) {
    print('Ошибка: не удалось найти версию или номер сборки в app_version.dart');
    exit(1);
  }

  final version = versionMatch.group(1)!;
  final buildNumber = buildMatch.group(1)!;
  final fullVersion = '$version+$buildNumber';

  print('Синхронизация версии: $version (сборка: $buildNumber)');

  // Обновляем pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    var pubspecContent = pubspecFile.readAsStringSync();
    pubspecContent = pubspecContent.replaceAll(
      RegExp(r'version: [^\n]+'),
      'version: $fullVersion # Sync with lib/config/app_version.dart'
    );
    pubspecFile.writeAsStringSync(pubspecContent);
    print('✓ Обновлен pubspec.yaml');
  }

  // Обновляем snapcraft.yaml
  final snapcraftFile = File('snap/snapcraft.yaml');
  if (snapcraftFile.existsSync()) {
    var snapcraftContent = snapcraftFile.readAsStringSync();
    snapcraftContent = snapcraftContent.replaceAll(
      RegExp(r'version: [^\n]+'),
      'version: $version # Sync with lib/config/app_version.dart'
    );
    snapcraftFile.writeAsStringSync(snapcraftContent);
    print('✓ Обновлен snap/snapcraft.yaml');
  }

  print('Синхронизация версий завершена!');
}