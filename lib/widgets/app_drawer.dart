import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/app_version.dart';
import 'package:quikxchat/utils/optimized_http_client.dart';
import 'package:quikxchat/widgets/drawer/drawer_header.dart';
import 'package:quikxchat/widgets/drawer/drawer_menu_groups.dart';
import 'package:quikxchat/widgets/drawer/drawer_dialogs.dart';
import 'package:quikxchat/widgets/matrix.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with TickerProviderStateMixin {
  Profile? _cachedProfile;
  bool _isLoadingProfile = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: Drawer(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        child: Column(
          children: [
            CustomDrawerHeader(
              profile: _cachedProfile,
              client: client,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerMenuGroups(
                    itemAnimations: _itemAnimations,
                    onCheckUpdates: _checkForUpdates,
                    onShowAbout: _showAboutDialog,
                  ),
                ],
              ),
            ),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Асинхронное обновление профиля
    Matrix.of(context).client.onSync.stream.listen((_) async {
      if (mounted) {
        await _loadProfile();
      }
    });
    
    // Немедленное обновление при старте
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _loadProfile();
    });
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ),);
    
    // Создаем контроллеры для каждого элемента меню
    const itemCount = 12;
    _itemControllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    
    _itemAnimations = _itemControllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutQuart,
        ),
      ),
    ).toList();
    
    // Запускаем анимации с задержкой
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      for (var i = 0; i < _itemControllers.length; i++) {
        Future.delayed(Duration(milliseconds: 50 + (i * 20)), () {
          if (mounted) _itemControllers[i].forward();
        });
      }
    });
  }

  Future<void> _loadProfile() async {
    if (_isLoadingProfile) return;
    
    final client = Matrix.of(context).client;
    if (!client.isLogged()) return;
    
    setState(() => _isLoadingProfile = true);
    
    try {
      final profile = await client.fetchOwnProfile();
      if (mounted) {
        setState(() {
          _cachedProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        '${AppConfig.applicationName} v${AppVersion.version}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }



  void _checkForUpdates(BuildContext context) async {
    try {
      final data = await OptimizedHttpClient().getJson('https://api.github.com/repos/IQUXAe/Quikx_chat/releases/latest');
      
      if (data != null) {
        final latestVersion = data['tag_name']?.replaceFirst('v', '') ?? data['name'];
        const currentVersion = AppVersion.version;
        
        if (latestVersion != currentVersion && latestVersion != null) {
          DrawerDialogs.showUpdateDialog(context, {
            'latest_version': latestVersion,
            'release_notes': data['body'] ?? 'Новая версия доступна',
            'download_url': data['html_url'],
          });
        } else {
          DrawerDialogs.showNoUpdateDialog(context);
        }
      } else {
        DrawerDialogs.showUpdateErrorDialog(context);
      }
    } catch (e) {
      DrawerDialogs.showUpdateErrorDialog(context);
    }
  }

  bool _isVersionLower(String current, String minimum) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minimumParts = minimum.split('.').map(int.parse).toList();
    
    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minimumPart = i < minimumParts.length ? minimumParts[i] : 0;
      
      if (currentPart < minimumPart) return true;
      if (currentPart > minimumPart) return false;
    }
    return false;
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> data) {
    DrawerDialogs.showUpdateDialog(context, data);
  }

  void _showAboutDialog(BuildContext context) {
    DrawerDialogs.showAboutDialog(context);
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

