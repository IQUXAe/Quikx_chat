import 'package:flutter/material.dart';
import '../config/amoled_theme.dart';

/// Демо AMOLED темы
class AmoledThemeDemo extends StatefulWidget {
  const AmoledThemeDemo({super.key});

  @override
  State<AmoledThemeDemo> createState() => _AmoledThemeDemoState();
}

class _AmoledThemeDemoState extends State<AmoledThemeDemo> {
  ExtendedThemeMode _currentTheme = ExtendedThemeMode.amoled;
  bool _useAmoled = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _useAmoled 
          ? AmoledTheme.buildAmoledTheme(context)
          : ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AMOLED Тема'),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _useAmoled = !_useAmoled;
                });
              },
              icon: Icon(_useAmoled ? Icons.brightness_1 : Icons.brightness_6),
              tooltip: _useAmoled ? 'Обычная тёмная тема' : 'AMOLED тема',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Заголовок
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AMOLED тема',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                'Экономия батареи на OLED экранах',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Глубокий черный цвет (#000000) позволяет OLED пикселям полностью выключаться, значительно экономя заряд батареи.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Сравнение цветов
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF121212), // Обычная тёмная тема
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Обычная'),
                          const Text(
                            '#121212',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF000000), // AMOLED
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AMOLED',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '#000000',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Демо сообщений
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сообщения',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildMessageBubble(
                      'Привет! Как дела?',
                      false,
                      '12:30',
                    ),
                    const SizedBox(height: 8),
                    _buildMessageBubble(
                      'Отлично! Пробую новую AMOLED тему 🔋',
                      true,
                      '12:31',
                    ),
                    const SizedBox(height: 8),
                    _buildMessageBubble(
                      'Круто! Она экономит батарею?',
                      false,
                      '12:32',
                    ),
                    const SizedBox(height: 8),
                    _buildMessageBubble(
                      'Да, заметно! На OLED экранах черные пиксели не светятся ✨',
                      true,
                      '12:33',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Элементы интерфейса
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Элементы интерфейса',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Переключатели
                    SwitchListTile(
                      title: const Text('Уведомления'),
                      subtitle: const Text('Показывать уведомления'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    
                    CheckboxListTile(
                      title: const Text('Автосохранение'),
                      subtitle: const Text('Сохранять файлы автоматически'),
                      value: true,
                      onChanged: (value) {},
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Слайдер
                    Text(
                      'Яркость: 60%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: 0.6,
                      onChanged: (value) {},
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Кнопки
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Применить'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Отмена'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Преимущества
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.battery_charging_full,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Преимущества AMOLED темы',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildBenefitItem(
                      Icons.battery_saver,
                      'Экономия батареи',
                      'До 30% меньше потребления на OLED экранах',
                      Colors.green,
                    ),
                    _buildBenefitItem(
                      Icons.visibility,
                      'Меньше напряжения глаз',
                      'Комфортное использование в темноте',
                      Colors.blue,
                    ),
                    _buildBenefitItem(
                      Icons.contrast,
                      'Высокий контраст',
                      'Идеальная читаемость текста',
                      Colors.orange,
                    ),
                    _buildBenefitItem(
                      Icons.style,
                      'Премиум внешний вид',
                      'Элегантный и современный дизайн',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_useAmoled 
                    ? 'AMOLED тема активна 🔋' 
                    : 'Обычная тёмная тема'),
              ),
            );
          },
          icon: const Icon(Icons.palette),
          label: const Text('Сменить тему'),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isOwn, String time) {
    return Row(
      mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isOwn) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Text('A', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOwn 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isOwn 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOwn 
                        ? Colors.white70 
                        : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOwn) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Text('Я', style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
