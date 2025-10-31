import 'package:flutter/material.dart';
import 'package:quikxchat/widgets/modern_back_button.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import '../../utils/message_translator.dart';
import '../../utils/translation_providers.dart';
import 'settings_translation.dart';

class SettingsTranslationView extends StatefulWidget {
  final SettingsTranslationController controller;
  const SettingsTranslationView(this.controller, {super.key});

  @override
  State<SettingsTranslationView> createState() => _SettingsTranslationViewState();
}

class _SettingsTranslationViewState extends State<SettingsTranslationView> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: ModernBackButton(),
        title: const Text('Translation Settings'),
        centerTitle: QuikxChatThemes.isColumnMode(context),
      ),
      body: ListTileTheme(
        iconColor: theme.textTheme.bodyLarge!.color,
        child: MaxWidthBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
              FutureBuilder<bool>(
                future: MessageTranslator.isEnabled,
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            isEnabled ? Icons.check_circle : Icons.cancel,
                            color: isEnabled ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEnabled ? 'Translation Active' : 'Translation Inactive',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isEnabled 
                                    ? 'Messages will be translated automatically'
                                    : 'Configure provider to enable translation',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              Text(
                'PROVIDER',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        return FutureBuilder<TranslationProvider>(
                          future: TranslationProviders.getCurrentProvider(),
                          builder: (context, snapshot) {
                            final currentProvider = snapshot.data ?? TranslationProvider.myMemory;
                            
                            return ListTile(
                              leading: const Icon(Icons.translate),
                              title: const Text('Translation Provider'),
                              subtitle: Text(
                                currentProvider.displayName,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () async {
                                final selected = await showDialog<TranslationProvider>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Select Provider'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: TranslationProvider.values
                                          .map(
                                            (provider) => ListTile(
                                              onTap: () => Navigator.pop(context, provider),
                                              leading: Icon(
                                                provider == currentProvider
                                                    ? Icons.radio_button_checked
                                                    : Icons.radio_button_unchecked,
                                                color: provider == currentProvider
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                              title: Text(provider.displayName),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                                if (selected != null) {
                                  await TranslationProviders.setProvider(selected);
                                  setState(() {});
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              
              const SizedBox(height: 24),
              
              Text(
                'LANGUAGE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    return FutureBuilder<bool>(
                      future: MessageTranslator.isEnabled,
                      builder: (context, enabledSnapshot) {
                        final isEnabled = enabledSnapshot.data ?? false;
                        
                        return FutureBuilder<TranslationProvider>(
                          future: TranslationProviders.getCurrentProvider(),
                          builder: (context, providerSnapshot) {
                            final provider = providerSnapshot.data ?? TranslationProvider.myMemory;
                            
                            return FutureBuilder<String>(
                              future: MessageTranslator.targetLanguage,
                              builder: (context, snapshot) {
                                final targetLang = snapshot.data ?? 'auto';
                                final languages = TranslationProviders.getLanguagesForProvider(provider);
                            
                                return ListTile(
                                  leading: Icon(
                                    Icons.language,
                                    color: isEnabled ? null : Colors.grey,
                                  ),
                                  title: Text(
                                    L10n.of(context).targetLanguage,
                                    style: TextStyle(
                                      color: isEnabled ? null : Colors.grey,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isEnabled ? (languages[targetLang] ?? targetLang) : 'Configure provider first',
                                    style: TextStyle(
                                      color: isEnabled ? theme.colorScheme.onSurface : Colors.grey,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: isEnabled ? null : Colors.grey,
                                  ),
                                  onTap: isEnabled ? () async {
                                    final selected = await showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(L10n.of(context).selectTargetLanguage),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: languages.entries
                                                .map(
                                                  (entry) => ListTile(
                                                    onTap: () => Navigator.pop(context, entry.key),
                                                    leading: Icon(
                                                      entry.key == targetLang
                                                          ? Icons.radio_button_checked
                                                          : Icons.radio_button_unchecked,
                                                      color: entry.key == targetLang
                                                          ? theme.colorScheme.primary
                                                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                    ),
                                                    title: Text(
                                                      entry.value,
                                                      style: TextStyle(
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    );
                                    if (selected != null) {
                                      await MessageTranslator.setTargetLanguage(selected);
                                      setLocalState(() {});
                                    }
                                  } : null,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'OPTIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    return FutureBuilder<bool>(
                      future: MessageTranslator.autoTranslateEnabled,
                      builder: (context, snapshot) {
                        final autoTranslate = snapshot.data ?? false;
                        return SwitchListTile(
                          secondary: const Icon(Icons.auto_awesome),
                          title: const Text('Auto-translate'),
                          subtitle: const Text('Automatically translate messages not in target language'),
                          value: autoTranslate,
                          onChanged: (value) async {
                            await MessageTranslator.setAutoTranslate(value);
                            setLocalState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'CACHE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.clear_all, color: Colors.red),
                  title: const Text('Clear Translation Cache'),
                  subtitle: const Text('Remove all cached translations'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Cache'),
                        content: const Text('Are you sure you want to clear all cached translations?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(L10n.of(context).cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await MessageTranslator.clearCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Translation cache cleared'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}