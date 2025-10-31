import 'package:flutter/material.dart';
import 'package:quikxchat/widgets/modern_back_button.dart';
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
              value: _aiEnabled,
              onChanged: (value) async {
                final store = Matrix.of(context).store;
                await AppSettings.aiEnabled.setItem(store, value);
                setState(() => _aiEnabled = value);
              },
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
              value: _voiceToTextEnabled && _aiEnabled,
              onChanged: _aiEnabled
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
