import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simplemessenger/config/setting_keys.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/widgets/layouts/max_width_body.dart';
import 'package:simplemessenger/widgets/matrix.dart';

class SettingsVoipView extends StatefulWidget {
  const SettingsVoipView({super.key});

  @override
  State<SettingsVoipView> createState() => _SettingsVoipViewState();
}

class _SettingsVoipViewState extends State<SettingsVoipView> {
  bool _voipEnabled = false;
  bool _microphonePermission = false;
  bool _cameraPermission = false;
  bool _phonePermission = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _loadSettings() async {
    final store = await SharedPreferences.getInstance();
    setState(() {
      _voipEnabled = store.getBool(SettingKeys.experimentalVoip) ?? false;
      _loading = false;
    });
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final cameraStatus = await Permission.camera.status;
    final phoneStatus = await Permission.phone.status;

    setState(() {
      _microphonePermission = micStatus.isGranted;
      _cameraPermission = cameraStatus.isGranted;
      _phonePermission = phoneStatus.isGranted;
    });
  }

  Future<void> _toggleVoip(bool enabled) async {
    final store = await SharedPreferences.getInstance();
    await store.setBool(SettingKeys.experimentalVoip, enabled);
    
    setState(() {
      _voipEnabled = enabled;
    });

    Matrix.of(context).createVoipPlugin();

    if (enabled && (!_microphonePermission || !_cameraPermission)) {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.camera,
      Permission.phone,
    ];

    final statuses = await permissions.request();
    
    setState(() {
      _microphonePermission = statuses[Permission.microphone]?.isGranted ?? false;
      _cameraPermission = statuses[Permission.camera]?.isGranted ?? false;
      _phonePermission = statuses[Permission.phone]?.isGranted ?? false;
    });

    if (!_microphonePermission || !_cameraPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Требуются разрешения для работы VoIP'),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки VoIP'),
      ),
      body: MaxWidthBody(
        child: ListView(
          children: [
            SwitchListTile.adaptive(
              title: const Text('Включить VoIP звонки'),
              subtitle: const Text('Голосовые и видео звонки через Matrix'),
              value: _voipEnabled,
              onChanged: _toggleVoip,
            ),
            const Divider(),
            
            if (_voipEnabled) ...[
              const ListTile(
                title: Text('Разрешения'),
                subtitle: Text('Необходимые разрешения для работы звонков'),
              ),
              
              ListTile(
                leading: Icon(
                  Icons.mic,
                  color: _microphonePermission ? Colors.green : Colors.red,
                ),
                title: const Text('Микрофон'),
                subtitle: Text(
                  _microphonePermission ? 'Разрешено' : 'Не разрешено',
                ),
                trailing: _microphonePermission 
                  ? const Icon(Icons.check, color: Colors.green)
                  : TextButton(
                      onPressed: _requestPermissions,
                      child: const Text('Разрешить'),
                    ),
              ),
              
              ListTile(
                leading: Icon(
                  Icons.videocam,
                  color: _cameraPermission ? Colors.green : Colors.red,
                ),
                title: const Text('Камера'),
                subtitle: Text(
                  _cameraPermission ? 'Разрешено' : 'Не разрешено',
                ),
                trailing: _cameraPermission 
                  ? const Icon(Icons.check, color: Colors.green)
                  : TextButton(
                      onPressed: _requestPermissions,
                      child: const Text('Разрешить'),
                    ),
              ),
              
              ListTile(
                leading: Icon(
                  Icons.phone,
                  color: _phonePermission ? Colors.green : Colors.red,
                ),
                title: const Text('Телефон'),
                subtitle: Text(
                  _phonePermission ? 'Разрешено' : 'Не разрешено',
                ),
                trailing: _phonePermission 
                  ? const Icon(Icons.check, color: Colors.green)
                  : TextButton(
                      onPressed: _requestPermissions,
                      child: const Text('Разрешить'),
                    ),
              ),
              
              const Divider(),
              
              const ListTile(
                title: Text('Инструкции'),
                subtitle: Text('Нажмите на иконку телефона в чате для звонка'),
                leading: Icon(Icons.info_outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}