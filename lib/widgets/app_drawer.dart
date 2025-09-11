import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:simplemessenger/config/app_config.dart';
import 'package:simplemessenger/config/app_version.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/utils/optimized_http_client.dart';
import 'package:simplemessenger/widgets/avatar.dart';
import 'package:simplemessenger/widgets/matrix.dart';

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
        child: Column(
          children: [
            // Header with large profile photo
            _buildProfileHeader(client),
                

            
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    iconColor: Colors.grey,
                    title: L10n.of(context).settings,
                    onTap: () => context.go('/rooms/settings'),
                    animationIndex: 0,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.security_outlined,
                    iconColor: Colors.red,
                    title: L10n.of(context).security,
                    onTap: () => context.go('/rooms/settings/security'),
                    animationIndex: 1,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.orange,
                    title: L10n.of(context).notifications,
                    onTap: () => context.go('/rooms/settings/notifications'),
                    animationIndex: 2,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple,
                    title: L10n.of(context).changeTheme,
                    onTap: () => context.go('/rooms/settings/style'),
                    animationIndex: 3,
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    context,
                    icon: Icons.archive_outlined,
                    iconColor: Colors.brown,
                    title: L10n.of(context).archive,
                    onTap: () => context.go('/rooms/archive'),
                    animationIndex: 4,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group_add_outlined,
                    iconColor: Colors.green,
                    title: L10n.of(context).newGroup,
                    onTap: () => context.go('/rooms/newgroup'),
                    animationIndex: 5,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.workspaces_outlined,
                    iconColor: Colors.blue,
                    title: L10n.of(context).newSpace,
                    onTap: () => context.go('/rooms/newspace'),
                    animationIndex: 6,
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    context,
                    icon: Icons.system_update_outlined,
                    iconColor: Colors.teal,
                    title: L10n.of(context).checkUpdates,
                    onTap: () => _checkForUpdates(context),
                    closeDrawer: false,
                    animationIndex: 7,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history_outlined,
                    iconColor: Colors.indigo,
                    title: L10n.of(context).changelog,
                    onTap: () => _showChangelog(context),
                    animationIndex: 8,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_outlined,
                    iconColor: Colors.cyan,
                    title: L10n.of(context).about,
                    onTap: () => _showAboutDialog(context),
                    closeDrawer: false,
                    animationIndex: 9,
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool closeDrawer = true,
    required int animationIndex,
  }) {
    if (animationIndex >= _itemAnimations.length) {
      return const SizedBox.shrink();
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (closeDrawer) {
                      Navigator.of(context).pop();
                    }
                    onTap();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: (iconColor ?? Colors.grey).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? Colors.grey,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _checkForUpdates(BuildContext context) async {
    final data = await OptimizedHttpClient().getJson('https://iquxae.pythonanywhere.com/api/updates');
    
    if (data != null) {
      final latestVersion = data['latest_version'];
      const currentVersion = AppVersion.version;
      final minSupportedVersion = data['min_supported_version'] ?? '0.1.0';
      
      if (_isVersionLower(currentVersion, minSupportedVersion)) {
        _showForceUpdateDialog(context, data);
      } else if (latestVersion != currentVersion) {
        _showUpdateDialog(context, data);
      } else {
        _showNoUpdateDialog(context);
      }
    } else {
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

  void _showChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).changelog),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: [
              _buildChangelogItem('0.2.3', L10n.of(context).currentVersion, [
                // TODO: Add localization keys for 0.2.3 changes
                'Placeholder for 0.2.3 changes',
              ]),
              _buildChangelogItem('0.2.2', '', [
                L10n.of(context).performanceOptimizationAndMemoryLeakFixes,
                L10n.of(context).improvedUserProfileCaching,
                L10n.of(context).centralizedVersionManagement,
                L10n.of(context).criticalSecurityIssuesFixed,
              ]),
              _buildChangelogItem('0.2.1', '', [
                L10n.of(context).pushNotificationsBeta,
                L10n.of(context).enhancedSecurityStability,
                L10n.of(context).completeLocalizationSupport,
              ]),
              _buildChangelogItem('0.2.0', '', [
                L10n.of(context).transitionToMatrix,
                L10n.of(context).endToEndEncryptionSupport,
                L10n.of(context).improvedUserInterface,
              ]),
              _buildChangelogItem('0.1.1', '', [
                L10n.of(context).bugFixesImprovements,
                L10n.of(context).performanceOptimizations,
              ]),
              _buildChangelogItem('0.1.0', '', [
                L10n.of(context).initialTestRelease,
                L10n.of(context).basicMessagingFunctionality,
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).close),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  Widget _buildChangelogItem(String version, String label, List<String> changes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'v$version',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ...changes.map((change) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(change)),
                ],
              ),
            ),),
          ],
        ),
      ),
    );
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