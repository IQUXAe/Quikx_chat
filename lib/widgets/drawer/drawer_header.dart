import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/avatar.dart';

class CustomDrawerHeader extends StatelessWidget {
  final Profile? profile;
  final Client client;

  const CustomDrawerHeader({
    super.key,
    required this.profile,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = profile?.displayName ?? 
        client.userID?.localpart ?? 
        L10n.of(context).user;
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
}