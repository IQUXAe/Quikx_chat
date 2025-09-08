import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:simplemessenger/config/themes.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:simplemessenger/widgets/avatar.dart';
import 'package:simplemessenger/widgets/matrix.dart';
import 'chat_list.dart';

class ClientChooserButton extends StatelessWidget {
  final ChatListController controller;

  const ClientChooserButton(this.controller, {super.key});

  List<PopupMenuEntry<Object>> _bundleMenuItems(BuildContext context) {
    final matrix = Matrix.of(context);
    final bundles = matrix.accountBundles.keys.toList()
      ..sort(
        (a, b) => a!.isValidMatrixId == b!.isValidMatrixId
            ? 0
            : a.isValidMatrixId && !b.isValidMatrixId
                ? -1
                : 1,
      );
    return <PopupMenuEntry<Object>>[
      for (final bundle in bundles) ...[
        if (matrix.accountBundles[bundle]!.length != 1 ||
            matrix.accountBundles[bundle]!.single!.userID != bundle)
          PopupMenuItem(
            value: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bundle!,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleMedium!.color,
                    fontSize: 14,
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ...matrix.accountBundles[bundle]!
            .whereType<Client>()
            .where((client) => client.isLogged())
            .map(
              (client) => PopupMenuItem(
                value: client,
                child: FutureBuilder<Profile?>(
                  future: client.fetchOwnProfile(),
                  builder: (context, snapshot) => Row(
                    children: [
                      Avatar(
                        mxContent: snapshot.data?.avatarUrl,
                        name: snapshot.data?.displayName ??
                            client.userID!.localpart,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          snapshot.data?.displayName ??
                              client.userID!.localpart!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => controller.editBundlesForAccount(
                          client.userID,
                          bundle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
      PopupMenuItem(
        value: SettingsAction.setStatus,
        child: Row(
          children: [
            const Icon(Icons.edit_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context).setStatus),
          ],
        ),
      ),
      PopupMenuItem(
        value: SettingsAction.addAccount,
        child: Row(
          children: [
            const Icon(Icons.person_add_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context).addAccount),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix.of(context);

    var clientCount = 0;
    matrix.accountBundles.forEach((key, value) => clientCount += value.length);
    return FutureBuilder<Profile>(
      future: matrix.client.isLogged() ? matrix.client.fetchOwnProfile() : null,
      builder: (context, snapshot) => Material(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(99),
        color: Colors.transparent,
        child: PopupMenuButton<Object>(
          popUpAnimationStyle: SimpleMessengerThemes.isColumnMode(context)
              ? AnimationStyle.noAnimation
              : null,
          onSelected: (o) => _clientSelected(o, context),
          itemBuilder: _bundleMenuItems,
          child: FutureBuilder<CachedPresence>(
            future: matrix.client.fetchCurrentPresence(matrix.client.userID!),
            builder: (context, presenceSnapshot) {
              final cached = presenceSnapshot.data;
              final hasStatusMsg = cached?.statusMsg?.isNotEmpty == true;
              
              return GestureDetector(
                onTap: hasStatusMsg ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cached!.statusMsg!),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } : null,
                child: Container(
                  decoration: hasStatusMsg ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ) : null,
                  child: Avatar(
                    mxContent: snapshot.data?.avatarUrl,
                    name: snapshot.data?.displayName ?? matrix.client.userID?.localpart,
                    size: 36,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _clientSelected(
    Object object,
    BuildContext context,
  ) async {
    if (object is Client) {
      controller.setActiveClient(object);
    } else if (object is String) {
      controller.setActiveBundle(object);
    } else if (object is SettingsAction) {
      switch (object) {
        case SettingsAction.setStatus:
          controller.setStatus();
          break;
        case SettingsAction.addAccount:
          final consent = await showOkCancelAlertDialog(
            context: context,
            title: L10n.of(context).addAccount,
            message: L10n.of(context).enableMultiAccounts,
            okLabel: L10n.of(context).next,
            cancelLabel: L10n.of(context).cancel,
          );
          if (consent != OkCancelResult.ok) return;
          context.go('/rooms/settings/addaccount');
          break;
        // Other actions moved to drawer
      }
    }
  }
}

enum SettingsAction {
  setStatus,
  addAccount,
}
