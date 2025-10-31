import 'package:flutter/material.dart';
import 'package:quikxchat/config/env_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/widgets/layouts/max_width_body.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/modern_back_button.dart';
import 'package:quikxchat/widgets/settings_card_tile.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  bool _aiEnabled = true;
  bool _voiceToTextEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  void _loadSettings() {
    final store = Matrix.of(context).store;
    final aiEnabled = AppSettings.aiEnabled.getItem(store);
    final voiceToTextEnabled = AppSettings.voiceToTextEnabled.getItem(store);
    if (_aiEnabled != aiEnabled || _voiceToTextEnabled != voiceToTextEnabled) {
      setState(() {
        _aiEnabled = aiEnabled;
        _voiceToTextEnabled = voiceToTextEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverConfigured = EnvConfig.v2tServerUrl.isNotEmpty && 
                             EnvConfig.v2tSecretKey.isNotEmpty;
    
    if (!serverConfigured) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI'),
          leading: const Center(child: ModernBackButton()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 80,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'AI Server Not Configured',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI features require V2T_SERVER_URL and V2T_SECRET_KEY to be configured during build.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI'),
        leading: const Center(child: ModernBackButton()),
      ),
      body: MaxWidthBody(
        withScrolling: false,
        child: ListView(
          children: [
            const SizedBox(height: 16),
            SettingsCardSwitch(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
              ),
              title: const Text('AI Features'),
              subtitle: const Text('Enable all AI-powered features'),
              value: _aiEnabled && serverConfigured,
              onChanged: serverConfigured ? (value) async {
                final store = Matrix.of(context).store;
                await AppSettings.aiEnabled.setItem(store, value);
                setState(() => _aiEnabled = value);
              } : null,
              position: CardPosition.single,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'FEATURES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary.withAlpha(180),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SettingsCardSwitch(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.text_fields, color: Colors.blue),
              ),
              title: const Text('Voice to Text'),
              subtitle: Text(
                serverConfigured
                    ? 'Convert voice messages to text'
                    : 'Server not configured',
                style: TextStyle(
                  color: serverConfigured ? null : Colors.red,
                ),
              ),
              value: _voiceToTextEnabled && _aiEnabled && serverConfigured,
              onChanged: _aiEnabled && serverConfigured
                  ? (value) async {
                      final store = Matrix.of(context).store;
                      await AppSettings.voiceToTextEnabled.setItem(store, value);
                      setState(() => _voiceToTextEnabled = value);
                    }
                  : null,
              position: CardPosition.single,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}
