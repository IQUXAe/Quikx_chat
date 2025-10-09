import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/unique_themes.dart';

/// Уникальный анимированный фон с плавающими элементами
class UniqueAnimatedBackground extends StatefulWidget {
  final Widget child;
  final String colorPalette;
  final bool enableParticles;

  const UniqueAnimatedBackground({
    super.key,
    required this.child,
    this.colorPalette = 'cosmic',
    this.enableParticles = true,
  });

  @override
  State<UniqueAnimatedBackground> createState() => _UniqueAnimatedBackgroundState();
}

class _UniqueAnimatedBackgroundState extends State<UniqueAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  
  final List<AnimatedParticle> _particles = [];
  final int _particleCount = 15;

  @override
  void initState() {
    super.initState();
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_gradientController);

    _gradientController.repeat();
    
    if (widget.enableParticles) {
      _initializeParticles();
      _particleController.repeat();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        AnimatedParticle(
          position: Offset(
            random.nextDouble(),
            random.nextDouble(),
          ),
          size: random.nextDouble() * 4 + 2,
          speed: random.nextDouble() * 0.5 + 0.2,
          color: UniqueQuikxThemes.colorPalettes[widget.colorPalette]![
            random.nextInt(4)
          ].withOpacity(0.1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gradientAnimation, _particleController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: UniqueQuikxThemes.createAnimatedBackgroundGradient(
              context,
              palette: widget.colorPalette,
              animationValue: _gradientAnimation.value,
            ),
          ),
          child: Stack(
            children: [
              // Плавающие частицы
              if (widget.enableParticles)
                CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    animationValue: _particleController.value,
                  ),
                  size: Size.infinite,
                ),
              
              // Основной контент
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

/// Анимированная частица
class AnimatedParticle {
  Offset position;
  final double size;
  final double speed;
  final Color color;

  AnimatedParticle({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
  });

  void update(double animationValue) {
    position = Offset(
      (position.dx + speed * 0.01) % 1.0,
      (position.dy + math.sin(animationValue * 2 * math.pi + position.dx * 10) * 0.001) % 1.0,
    );
  }
}

/// Художник для рисования частиц
class ParticlePainter extends CustomPainter {
  final List<AnimatedParticle> particles;
  final double animationValue;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update(animationValue);
      
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
          particle.position.dx * size.width,
          particle.position.dy * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// Уникальная анимированная навигационная панель
class UniqueBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String colorPalette;
  final List<UniqueNavItem> items;

  const UniqueBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.colorPalette = 'cosmic',
  });

  @override
  State<UniqueBottomNavigation> createState() => _UniqueBottomNavigationState();
}

class _UniqueBottomNavigationState extends State<UniqueBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    
    _rippleController = AnimationController(
      duration: UniqueQuikxThemes.mediumAnimation,
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: UniqueQuikxThemes.fastCurve,
    ));
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _tappedIndex = index);
    _rippleController.forward().then((_) {
      _rippleController.reset();
      setState(() => _tappedIndex = null);
    });
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = UniqueQuikxThemes.colorPalettes[widget.colorPalette]!;

    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UniqueQuikxThemes.borderRadiusXL),
          topRight: Radius.circular(UniqueQuikxThemes.borderRadiusXL),
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UniqueQuikxThemes.borderRadiusXL),
          topRight: Radius.circular(UniqueQuikxThemes.borderRadiusXL),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
              top: 12,
              left: 16,
              right: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == widget.currentIndex;
                final isTapped = index == _tappedIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              UniqueQuikxThemes.borderRadiusL,
                            ),
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      palette[0].withOpacity(0.2),
                                      palette[1].withOpacity(0.1),
                                    ],
                                  )
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple эффект
                              if (isTapped)
                                Container(
                                  width: 56 * _rippleAnimation.value,
                                  height: 56 * _rippleAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: palette[0].withOpacity(
                                      0.3 * (1 - _rippleAnimation.value),
                                    ),
                                  ),
                                ),
                              
                              // Иконка и текст
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: UniqueQuikxThemes.shortAnimation,
                                    curve: UniqueQuikxThemes.bouncyCurve,
                                    transform: Matrix4.identity()
                                      ..scale(isSelected ? 1.1 : 1.0),
                                    child: Icon(
                                      item.icon,
                                      size: 24,
                                      color: isSelected
                                          ? palette[0]
                                          : theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: UniqueQuikxThemes.shortAnimation,
                                    style: TextStyle(
                                      fontSize: isSelected ? 12 : 10,
                                      fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? palette[0]
                                          : theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    child: Text(item.label),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Элемент навигации
class UniqueNavItem {
  final IconData icon;
  final String label;

  const UniqueNavItem({
    required this.icon,
    required this.label,
  });
}

/// Уникальная анимированная AppBar
class UniqueAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final String colorPalette;
  final bool showGradient;

  const UniqueAppBar({
    super.key,
    required this.title,
    this.actions,
    this.colorPalette = 'cosmic',
    this.showGradient = true,
  });

  @override
  State<UniqueAppBar> createState() => _UniqueAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _UniqueAppBarState extends State<UniqueAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_shimmerController);

    if (widget.showGradient) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = UniqueQuikxThemes.colorPalettes[widget.colorPalette]!;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: widget.preferredSize.height + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            gradient: widget.showGradient
                ? LinearGradient(
                    begin: Alignment(-1.0 + _shimmerAnimation.value * 2, -1.0),
                    end: Alignment(0.0 + _shimmerAnimation.value * 2, 1.0),
                    colors: [
                      theme.colorScheme.surface,
                      palette[0].withOpacity(0.1),
                      palette[1].withOpacity(0.05),
                      theme.colorScheme.surface,
                    ],
                  )
                : null,
            color: widget.showGradient ? null : theme.colorScheme.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (widget.actions != null) ...widget.actions!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
