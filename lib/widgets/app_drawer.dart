import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/app_version.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/optimized_http_client.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';

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
            // Header with large profile photo
            _buildProfileHeader(client),
                

            
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  // Группа настроек - НОВЫЙ ДИЗАЙН
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    iconColor: Colors.grey,
                    title: L10n.of(context).settings,
                    onTap: () => context.go('/rooms/settings'),
                    position: CardPosition.first,
                    animationIndex: 0,
                  ),
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.security_outlined,
                    iconColor: Colors.red,
                    title: L10n.of(context).security,
                    onTap: () => context.go('/rooms/settings/security'),
                    position: CardPosition.middle,
                    animationIndex: 1,
                  ),
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.orange,
                    title: L10n.of(context).notifications,
                    onTap: () => context.go('/rooms/settings/notifications'),
                    position: CardPosition.middle,
                    animationIndex: 2,
                  ),
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple,
                    title: L10n.of(context).changeTheme,
                    onTap: () => context.go('/rooms/settings/style'),
                    position: CardPosition.last,
                    animationIndex: 3,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Группа действий
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.archive_outlined,
                    iconColor: Colors.brown,
                    title: L10n.of(context).archive,
                    onTap: () => context.go('/rooms/archive'),
                    position: CardPosition.first,
                    animationIndex: 4,
                  ),
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.group_add_outlined,
                    iconColor: Colors.green,
                    title: L10n.of(context).newGroup,
                    onTap: () => context.go('/rooms/newgroup'),
                    position: CardPosition.middle,
                    animationIndex: 5,
                  ),
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.workspaces_outlined,
                    iconColor: Colors.blue,
                    title: L10n.of(context).newSpace,
                    onTap: () => context.go('/rooms/newspace'),
                    position: CardPosition.last,
                    animationIndex: 6,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Группа информации
                  if (!kIsWeb)
                    _buildGroupedDrawerItem(
                      context,
                      icon: Icons.system_update_outlined,
                      iconColor: Colors.teal,
                      title: L10n.of(context).checkUpdates,
                      onTap: () => _checkForUpdates(context),
                      closeDrawer: false,
                      position: CardPosition.first,
                      animationIndex: 7,
                    ),
                  _buildGroupedDrawerItem(
                    context,
                    icon: Icons.info_outlined,
                    iconColor: Colors.cyan,
                    title: L10n.of(context).about,
                    onTap: () => _showAboutDialog(context),
                    closeDrawer: false,
                    position: kIsWeb ? CardPosition.single : CardPosition.last,
                    animationIndex: 8,
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${AppConfig.applicationName} v${AppVersion.version}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
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

  Widget _buildProfileHeader(Client client) {
    final theme = Theme.of(context);
    final profile = _cachedProfile;
    final displayName = profile?.displayName ?? client.userID?.localpart ?? L10n.of(context).user;
    final userId = client.userID ?? '';
    
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        image: profile?.avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(profile!.avatarUrl!.getThumbnail(
                  client,
                  width: 200,
                  height: 200,
                ).toString(),),
                fit: BoxFit.cover,
              )
            : null,
        gradient: profile?.avatarUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.secondary.withOpacity(0.8),
                ],
              )
            : null,
      ),
      child: Stack(
        children: [
          if (profile?.avatarUrl != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Avatar(
                    mxContent: profile?.avatarUrl,
                    name: displayName,
                    size: 64,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool closeDrawer = true,
    required CardPosition position,
    required int animationIndex,
  }) {
    if (animationIndex >= _itemAnimations.length) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    
    EdgeInsets getMargin() {
      switch (position) {
        case CardPosition.single:
          return const EdgeInsets.symmetric(horizontal: 16, vertical: 4);
        case CardPosition.first:
          return const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 1);
        case CardPosition.middle:
          return const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 1);
        case CardPosition.last:
          return const EdgeInsets.only(left: 16, right: 16, top: 1, bottom: 4);
      }
    }
    
    BorderRadius getBorderRadius() {
      switch (position) {
        case CardPosition.single:
          return BorderRadius.circular(12);
        case CardPosition.first:
          return const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          );
        case CardPosition.middle:
          return BorderRadius.zero;
        case CardPosition.last:
          return const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );
      }
    }
    
    return AnimatedBuilder(
      animation: _itemAnimations[animationIndex],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (1 - _itemAnimations[animationIndex].value) * -20,
            0,
          ),
          child: Opacity(
            opacity: _itemAnimations[animationIndex].value,
            child: _AnimatedMenuItem(
              margin: getMargin(),
              borderRadius: getBorderRadius(),
              backgroundColor: theme.colorScheme.surfaceContainer,
              onTap: () {
                if (closeDrawer) {
                  Navigator.of(context).pop();
                }
                onTap();
              },
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: getBorderRadius(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _checkForUpdates(BuildContext context) async {
    try {
      final data = await OptimizedHttpClient().getJson('https://api.github.com/repos/IQUXAe/Quikx_chat/releases/latest');
      
      if (data != null) {
        final latestVersion = data['tag_name']?.replaceFirst('v', '') ?? data['name'];
        const currentVersion = AppVersion.version;
        
        if (latestVersion != currentVersion && latestVersion != null) {
          _showUpdateDialog(context, {
            'latest_version': latestVersion,
            'release_notes': data['body'] ?? 'Новая версия доступна',
            'download_url': data['html_url'],
          });
        } else {
          _showNoUpdateDialog(context);
        }
      } else {
        _showUpdateErrorDialog(context);
      }
    } catch (e) {
      _showUpdateErrorDialog(context);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).updateAvailable),
        content: Text('${L10n.of(context).newVersionAvailable(data['latest_version'])}\n\n${data['release_notes'] ?? ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).later),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (data['download_url'] != null) {
                launchUrl(Uri.parse(data['download_url']));
              }
            },
            child: Text(L10n.of(context).update),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  void _showForceUpdateDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).forceUpdate),
        content: Text(L10n.of(context).forceUpdateMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (data['download_url'] != null) {
                launchUrl(Uri.parse(data['download_url']));
              }
            },
            child: Text(L10n.of(context).update),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).noUpdates),
        content: Text(L10n.of(context).latestVersion(AppVersion.version)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  void _showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).oopsSomethingWentWrong),
        content: Text(L10n.of(context).errorCheckingUpdates),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }





  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConfig.applicationName,
        applicationVersion: AppVersion.version,
        applicationIcon: Image.asset('assets/logo.png', width: 64, height: 64),
        children: [
          Text(L10n.of(context).simpleSecureMessaging),
          const SizedBox(height: 16),
          Text(L10n.of(context).developerIquxae),
          const SizedBox(height: 8),
          Text(L10n.of(context).builtWithFlutter),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
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

class _AnimatedMenuItem extends StatefulWidget {
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget child;

  const _AnimatedMenuItem({
    required this.margin,
    required this.borderRadius,
    required this.backgroundColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_AnimatedMenuItem> createState() => _AnimatedMenuItemState();
}

class _AnimatedMenuItemState extends State<_AnimatedMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: widget.borderRadius,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: widget.borderRadius,
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) {
                  _controller.reverse();
                  widget.onTap();
                },
                onTapCancel: () => _controller.reverse(),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}