import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


import 'package:audio_session/audio_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webrtc_interface/webrtc_interface.dart' hide Navigator;

import 'package:simplemessenger/pages/dialer/enhanced_dialer.dart';

import '../../widgets/matrix.dart';
import '../../widgets/simple_messenger_app.dart';

class EnhancedVoipPlugin with WidgetsBindingObserver implements WebRTCDelegate {
  final MatrixState matrix;
  Client get client => matrix.client;
  
  late VoIP voip;
  bool background = false;
  bool speakerOn = false;
  AudioPlayer? _audioPlayer;
  AudioSession? _audioSession;
  
  BuildContext get context => matrix.context;

  EnhancedVoipPlugin(this.matrix) {
    voip = VoIP(client, this);
    _initializeAudio();
    if (!kIsWeb) {
      final wb = WidgetsBinding.instance;
      wb.addObserver(this);
      didChangeAppLifecycleState(wb.lifecycleState);
    }
    _setupCallKit();
  }

  Future<void> _initializeAudio() async {
    try {
      if (!kIsWeb) {
        _audioPlayer = AudioPlayer();
        
        if (Platform.isAndroid || Platform.isIOS) {
          _audioSession = await AudioSession.instance;
          await _audioSession!.configure(const AudioSessionConfiguration.speech());
        }
      }
    } catch (e) {
      Logs().e('Failed to initialize audio: $e');
    }
  }

  Future<void> _setupCallKit() async {
    // CallKit setup will be implemented later
    // For now, we'll use basic notifications
  }





  @override
  void didChangeAppLifecycleState(AppLifecycleState? state) {
    background = (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused);
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return true; // Desktop platforms don't need permission requests
    }
    
    try {
      final permissions = <Permission>[
        Permission.microphone,
        Permission.camera,
      ];
      
      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.phone,
          Permission.systemAlertWindow,
        ]);
      }
      
      final statuses = await permissions.request();
      return statuses.values.every((status) => 
          status == PermissionStatus.granted || 
          status == PermissionStatus.limited);
    } catch (e) {
      Logs().e('Permission request failed: $e');
      return true; // Assume permissions are granted on error
    }
  }

  void addCallingOverlay(String callId, CallSession call) {
    final navigatorContext = SimpleMessengerApp.router.routerDelegate
        .navigatorKey.currentContext ?? context;

    showDialog(
      context: navigatorContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: false,
        child: EnhancedCalling(
          context: context,
          client: client,
          callId: callId,
          call: call,
          onClear: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  MediaDevices get mediaDevices => webrtc_impl.navigator.mediaDevices;

  @override
  bool get isWeb => kIsWeb;

  @override
  Future<RTCPeerConnection> createPeerConnection(
    Map<String, dynamic> configuration, [
    Map<String, dynamic> constraints = const {},
  ]) =>
      webrtc_impl.createPeerConnection(configuration, constraints);

  @override
  Future<void> playRingtone() async {
    if (background || kIsWeb) return;
    
    try {
      await _playRingtoneWithAudio();
    } catch (e) {
      Logs().e('Failed to play ringtone: $e');
    }
  }

  Future<void> _playRingtoneWithAudio() async {
    if (kIsWeb || _audioPlayer == null) return;
    
    try {
      await _audioPlayer!.setAsset('assets/sounds/phone.ogg');
      await _audioPlayer!.setLoopMode(LoopMode.all);
      await _audioPlayer!.play();
    } catch (e) {
      Logs().e('Ringtone playback failed: $e');
    }
  }

  @override
  Future<void> stopRingtone() async {
    if (kIsWeb || _audioPlayer == null) return;
    
    try {
      await _audioPlayer!.stop();
    } catch (e) {
      Logs().e('Failed to stop ringtone: $e');
    }
  }

  @override
  Future<void> handleNewCall(CallSession call) async {
    try {
      // Request permissions first
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Register listeners
      await registerListeners(call);
      
      // Enable wakelock for video calls
      if (call.type == CallType.kVideo) {
        await WakelockPlus.enable();
      }

      // Platform-specific handling
      if (Platform.isAndroid) {
        await _handleAndroidCall(call);
      } else if (Platform.isIOS) {
        await _handleIOSCall(call);
      }
      
      // Show calling overlay
      addCallingOverlay(call.callId, call);
      
    } catch (e) {
      Logs().e('Failed to handle new call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при инициации звонка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleAndroidCall(CallSession call) async {
    try {
      // Setup foreground service
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'voip_channel',
          channelName: 'VoIP Calls',
          channelDescription: 'Incoming and outgoing calls',
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
        ),
      );

      // Start foreground service
      FlutterForegroundTask.startService(
        notificationTitle: 'Входящий звонок',
        notificationText: call.room.getLocalizedDisplayname(),
      );

      // Wake up screen and show on lock screen
      FlutterForegroundTask.setOnLockScreenVisibility(true);
      FlutterForegroundTask.wakeUpScreen();
      FlutterForegroundTask.launchApp();
    } catch (e) {
      Logs().e('Android call setup failed: $e');
    }
  }

  Future<void> _handleIOSCall(CallSession call) async {
    try {
      // iOS CallKit integration will be implemented later
      // For now, use basic notifications
      Logs().i('iOS call handling - using basic notifications');
    } catch (e) {
      Logs().e('iOS call setup failed: $e');
    }
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    try {
      // Stop ringtone
      await stopRingtone();
      
      // Disable wakelock
      if (session.type == CallType.kVideo) {
        try {
          await WakelockPlus.disable();
        } catch (e) {
          Logs().w('Failed to disable wakelock: $e');
        }
      }

      // Platform-specific cleanup
      if (!kIsWeb && Platform.isAndroid) {
        try {
          FlutterForegroundTask.stopService();
          FlutterForegroundTask.setOnLockScreenVisibility(false);
        } catch (e) {
          Logs().w('Failed Android cleanup: $e');
        }
      }
      
      // Reset audio session
      if (!kIsWeb && _audioSession != null) {
        try {
          await _audioSession!.setActive(false);
        } catch (e) {
          Logs().w('Failed to deactivate audio session: $e');
        }
      }
      
    } catch (e) {
      Logs().e('Failed to handle call ended: $e');
    }
  }

  @override
  Future<void> handleGroupCallEnded(GroupCallSession groupCall) async {
    // TODO: implement handleGroupCallEnded
  }

  @override
  Future<void> handleNewGroupCall(GroupCallSession groupCall) async {
    // TODO: implement handleNewGroupCall
  }

  @override
  bool get canHandleNewCall =>
      voip.currentCID == null && voip.currentGroupCID == null;

  @override
  Future<void> handleMissedCall(CallSession session) async {
    // TODO: Show missed call notification
  }

  @override
  EncryptionKeyProvider? get keyProvider => null;

  @override
  Future<void> registerListeners(CallSession session) async {
    session.onCallStateChanged.stream.listen((state) {
      Logs().d('Call state changed: $state');
      
      // Handle state-specific actions
      switch (state) {
        case CallState.kConnected:
          stopRingtone();
          break;
        case CallState.kEnded:
          handleCallEnded(session);
          break;
        default:
          break;
      }
    });
    
    session.onCallEventChanged.stream.listen((event) {
      Logs().d('Call event changed: $event');
    });
  }

  void dispose() {
    try {
      if (!kIsWeb) {
        _audioPlayer?.dispose();
        _audioSession?.setActive(false);
      }
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      Logs().e('Error during VoIP plugin dispose: $e');
    }
  }
}