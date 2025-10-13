// Пример использования новых карточек настроек
// Этот файл демонстрирует, как выглядят обновленные настройки

import 'package:flutter/material.dart';
import 'lib/widgets/settings_card_tile.dart';

class ExampleSettingsPage extends StatelessWidget {
  const ExampleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки с карточками'),
      ),
      body: ListView(
        children: [
          // Заголовок секции
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Основные настройки',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Карточка с иконкой
          SettingsCardTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.palette_outlined, color: Colors.purple),
            ),
            title: const Text('Тема оформления'),
            onTap: () {},
          ),
          
          // Карточка с переключателем
          SettingsCardSwitch(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.orange),
            ),
            title: const Text('Уведомления'),
            subtitle: const Text('Получать push-уведомления'),
            value: true,
            onChanged: (value) {},
          ),
          
          // Отступ между секциями
          const SizedBox(height: 24),
          
          // Следующая секция
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Дополнительно',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SettingsCardTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.red),
            ),
            title: const Text('Безопасность'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}