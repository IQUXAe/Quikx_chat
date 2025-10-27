import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quikxchat/widgets/layouts/login_scaffold.dart';
import 'server_selection.dart';

class ServerSelectionView extends StatelessWidget {
  final ServerSelectionController controller;

  const ServerSelectionView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoginScaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Выбор сервера'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Выберите домашний сервер для регистрации:',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: controller.servers.isEmpty
                  ? Center(
                      child: Text(
                        'Серверы будут добавлены позже',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.servers.length,
                      itemBuilder: (context, index) {
                        final server = controller.servers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(server.name),
                            leading: Icon(
                              controller.selectedServer == server.id
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                            onTap: () => controller.selectServer(server.id),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: controller.isLoading
                  ? null
                  : controller.continueWithSelectedServer,
              child: controller.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Продолжить'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                side: BorderSide(color: theme.colorScheme.secondary),
              ),
              onPressed: controller.isLoading ? null : controller.continueWithUniversal,
              child: const Text('Универсальная регистрация'),
            ),
            const SizedBox(height: 16),
            Text(
              'Список серверов взят с servers.joinmatrix.org',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}