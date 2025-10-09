import 'package:flutter/material.dart';
import '../widgets/unique_animated_background.dart';
import '../widgets/unique_chat_bubble.dart';
import '../widgets/unique_theme_selector.dart';
import '../config/unique_themes.dart';

/// Демо экран нового уникального дизайна
class UniqueDesignDemo extends StatefulWidget {
  const UniqueDesignDemo({super.key});

  @override
  State<UniqueDesignDemo> createState() => _UniqueDesignDemoState();
}

class _UniqueDesignDemoState extends State<UniqueDesignDemo>
    with TickerProviderStateMixin {
  String _currentPalette = 'cosmic';
  Brightness _brightness = Brightness.light;
  late AnimationController _demoController;
  
  final List<String> _demoMessages = [
    'Привет! Как дела? 👋',
    'Отлично! Смотри какой новый дизайн!',
    'Вау! Очень красиво! 🔥',
    'Да, теперь приложение выглядит уникально',
    'Мне нравятся эти градиенты и анимации ✨',
    'И цветовые палитры просто супер!',
  ];

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _demoController.repeat();
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: UniqueQuikxThemes.buildUniqueTheme(
        context,
        _brightness,
        colorPalette: _currentPalette,
      ),
      child: Scaffold(
        body: UniqueAnimatedBackground(
          colorPalette: _currentPalette,
          enableParticles: true,
          child: SafeArea(
            child: Column(
              children: [
                // Заголовок демо
                _buildDemoHeader(),
                
                // Основной контент
                Expanded(
                  child: PageView(
                    children: [
                      _buildChatDemo(),
                      _buildThemeSelector(),
                      _buildFeaturesList(),
                    ],
                  ),
                ),
                
                // Навигация
                _buildDemoNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHeader() {
    final palette = UniqueQuikxThemes.colorPalettes[_currentPalette]!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette[0].withOpacity(0.9),
            palette[1].withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QuikxChat',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Новый уникальный дизайн',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleBrightness,
                icon: Icon(
                  _brightness == Brightness.light 
                      ? Icons.dark_mode 
                      : Icons.light_mode,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatDemo() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _demoMessages.length,
      itemBuilder: (context, index) {
        final isOwnMessage = index % 2 == 1;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              if (!isOwnMessage) ...[
                UniqueAnimatedAvatar(
                  name: 'Demo User',
                  colorPalette: _currentPalette,
                  size: 40,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: UniqueChatBubble(
                  isOwnMessage: isOwnMessage,
                  colorPalette: _currentPalette,
                  child: Text(
                    _demoMessages[index],
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white : null,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (isOwnMessage) ...[
                const SizedBox(width: 12),
                const UniqueMessageStatusIndicator(status: MessageStatus.read),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Выберите цветовую палитру',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          UniqueThemeSelector(
            currentPalette: _currentPalette,
            onPaletteChanged: (palette) {
              setState(() => _currentPalette = palette);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.palette, 'title': 'Уникальные цветовые палитры', 'desc': '5 красивых градиентных тем'},
      {'icon': Icons.animation, 'title': 'Плавные анимации', 'desc': 'Современные переходы и эффекты'},
      {'icon': Icons.bubble_chart, 'title': 'Стильные пузыри сообщений', 'desc': 'Градиенты и тени'},
      {'icon': Icons.auto_awesome, 'title': 'Анимированный фон', 'desc': 'Плавающие частицы'},
      {'icon': Icons.face, 'title': 'Динамические аватары', 'desc': 'Вращающиеся градиенты'},
      {'icon': Icons.navigation, 'title': 'Современная навигация', 'desc': 'Красивые переходы'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        final palette = UniqueQuikxThemes.colorPalettes[_currentPalette]!;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: palette[0].withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette[0], palette[1]],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoNavigation() {
    final palette = UniqueQuikxThemes.colorPalettes[_currentPalette]!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.chat,
            label: 'Чат',
            color: palette[0],
          ),
          _buildNavButton(
            icon: Icons.palette,
            label: 'Темы',
            color: palette[1],
          ),
          _buildNavButton(
            icon: Icons.star,
            label: 'Функции',
            color: palette[2],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBrightness() {
    setState(() {
      _brightness = _brightness == Brightness.light 
          ? Brightness.dark 
          : Brightness.light;
    });
  }
}
