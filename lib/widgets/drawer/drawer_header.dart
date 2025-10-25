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
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (profile?.avatarUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  profile!.avatarUrl!.getThumbnail(
                    client,
                    width: 400,
                    height: 400,
                  ).toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
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
                      color: Colors.white.withValues(alpha: 0.3),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userId,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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