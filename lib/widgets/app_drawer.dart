import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/app_version.dart';
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
        backgroundColor: theme.colorScheme.surface,
        child: Column(
          children: [
            CustomDrawerHeader(
              profile: _cachedProfile,
              client: client,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  DrawerMenuGroups(
                    itemAnimations: _itemAnimations,
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
    
    Matrix.of(context).client.onSync.stream.listen((_) async {
      if (mounted) await _loadProfile();
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _loadProfile();
    });
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ),);
    
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      for (var i = 0; i < _itemControllers.length; i++) {
        Future.delayed(Duration(milliseconds: 50 + (i * 30)), () {
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
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

