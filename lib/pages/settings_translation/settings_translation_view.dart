import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import '../../utils/message_translator.dart';
import '../../utils/translation_providers.dart';
import '../../config/setting_keys.dart';
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
        leading: const BackButton(),
        title: const Text('Translation Settings'),
        centerTitle: QuikxChatThemes.isColumnMode(context),
      ),
      body: ListTileTheme(
        iconColor: theme.textTheme.bodyLarge!.color,
        child: MaxWidthBody(
          child: Column(
            children: [
              // Translation Provider Selection
              StatefulBuilder(
                builder: (context, setLocalState) {
                  return FutureBuilder<TranslationProvider>(
                    future: TranslationProviders.getCurrentProvider(),
                    builder: (context, snapshot) {
                      final currentProvider = snapshot.data ?? TranslationProvider.myMemory;
                      
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.translate, color: Colors.blue),
                        ),
                        title: const Text('Translation Provider'),
                        subtitle: Text(currentProvider.displayName),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          final selected = await showDialog<TranslationProvider>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: const Text('Select Translation Provider'),
                              children: TranslationProvider.values
                                  .map(
                                    (provider) => SimpleDialogOption(
                                      onPressed: () => Navigator.pop(context, provider),
                                      child: Text(provider.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                  .toList(),
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
              
              const SizedBox(height: 8),
              Divider(color: theme.dividerColor),
              
              // Provider Configuration
              StatefulBuilder(
                builder: (context, setLocalState) {
                  return FutureBuilder<TranslationProvider>(
                    future: TranslationProviders.getCurrentProvider(),
                    builder: (context, snapshot) {
                      final provider = snapshot.data ?? TranslationProvider.myMemory;
                      return _buildProviderConfig(context, provider, setLocalState);
                    },
                  );
                },
              ),
              

              
              // Target Language Selection
              StatefulBuilder(
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
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isEnabled ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.language, 
                                    color: isEnabled ? Colors.green : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  L10n.of(context).targetLanguage,
                                  style: TextStyle(
                                    color: isEnabled ? null : Colors.grey,
                                  ),
                                ),
                                subtitle: Text(
                                  isEnabled ? (languages[targetLang] ?? targetLang) : 'Provider not configured',
                                  style: TextStyle(
                                    color: isEnabled ? null : Colors.grey,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_drop_down,
                                  color: isEnabled ? null : Colors.grey,
                                ),
                                onTap: isEnabled ? () async {
                              final selected = await showDialog<String>(
                                context: context,
                                builder: (context) => SimpleDialog(
                                  title:
                                      Text(L10n.of(context).selectTargetLanguage),
                                  children: languages.entries
                                      .map(
                                        (entry) => SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, entry.key),
                                          child: Text(entry.value),
                                        ),
                                      )
                                      .toList(),
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
              
              const SizedBox(height: 8),
              Divider(color: theme.dividerColor),
              
              // Clear Translation Cache
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.clear_all, color: Colors.red),
                ),
                title: const Text('Clear Translation Cache'),
                subtitle: const Text('Remove all cached translations'),
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
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await MessageTranslator.clearCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Translation cache cleared'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProviderConfig(BuildContext context, TranslationProvider provider, StateSetter setState) {
    switch (provider) {
      case TranslationProvider.disabled:
        return _buildDisabledConfig(context);
      case TranslationProvider.myMemory:
        return _buildMyMemoryConfig(context, setState);
      case TranslationProvider.googleTranslate:
        return _buildGoogleConfig(context, setState);
      case TranslationProvider.libreTranslate:
        return _buildLibreTranslateConfig(context, setState);
    }
  }
  
  Widget _buildDisabledConfig(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.translate_outlined, color: Colors.grey),
          title: Text('Translation Disabled'),
          subtitle: Text('Select a provider to enable translation'),
        ),
        const SizedBox(height: 8),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }
  
  Widget _buildMyMemoryConfig(BuildContext context, StateSetter setState) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.info, color: Colors.blue),
          title: Text('MyMemory Configuration'),
          subtitle: Text('Free service ready to use'),
        ),
        const SizedBox(height: 8),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }
  
  Widget _buildGoogleConfig(BuildContext context, StateSetter setState) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.info, color: Colors.orange),
          title: Text('Google Translate Configuration'),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('API Key'),
          subtitle: const Text('Required for Google Translate'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showGoogleApiKeyDialog(context, setState),
        ),
        const SizedBox(height: 8),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }
  
  Widget _buildLibreTranslateConfig(BuildContext context, StateSetter setState) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.info, color: Colors.green),
          title: Text('LibreTranslate Configuration'),
        ),
        ListTile(
          leading: const Icon(Icons.link),
          title: const Text('Endpoint URL'),
          subtitle: const Text('Server URL'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showEndpointDialog(context, setState),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('API Key (Optional)'),
          subtitle: const Text('Optional'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showLibreApiKeyDialog(context, setState),
        ),
        const SizedBox(height: 8),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }
  

  
  void _showGoogleApiKeyDialog(BuildContext context, StateSetter setState) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString(SettingKeys.googleTranslateApiKey) ?? '';
    final controller = TextEditingController(text: currentKey);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Translate API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'AIza...',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      if (result.isEmpty) {
        await prefs.remove(SettingKeys.googleTranslateApiKey);
      } else {
        await prefs.setString(SettingKeys.googleTranslateApiKey, result);
      }
      setState(() {});
    }
  }
  
  void _showEndpointDialog(BuildContext context, StateSetter setState) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEndpoint = prefs.getString(SettingKeys.libreTranslateEndpoint) ?? 'https://libretranslate.com';
    final controller = TextEditingController(text: currentEndpoint);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LibreTranslate Endpoint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Endpoint URL',
            hintText: 'https://libretranslate.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await prefs.setString(SettingKeys.libreTranslateEndpoint, result);
      setState(() {});
    }
  }
  
  void _showLibreApiKeyDialog(BuildContext context, StateSetter setState) async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString(SettingKeys.libreTranslateApiKey) ?? '';
    final controller = TextEditingController(text: currentKey);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LibreTranslate API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key (Optional)',
            hintText: 'your-api-key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      if (result.isEmpty) {
        await prefs.remove(SettingKeys.libreTranslateApiKey);
      } else {
        await prefs.setString(SettingKeys.libreTranslateApiKey, result);
      }
      setState(() {});
    }
  }
}