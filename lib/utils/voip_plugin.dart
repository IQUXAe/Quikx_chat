import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:webrtc_interface/webrtc_interface.dart' hide Navigator;

import 'package:simplemessenger/pages/dialer/dialer.dart';
import 'package:simplemessenger/utils/platform_infos.dart';
import '../../utils/voip/user_media_manager.dart';
import '../widgets/matrix.dart';
import '../widgets/simple_messenger_app.dart';

class VoipPlugin with WidgetsBindingObserver implements WebRTCDelegate {
  final MatrixState matrix;
  Client get client => matrix.client;
  VoipPlugin(this.matrix) {
    voip = VoIP(client, this);
    if (!kIsWeb) {
      final wb = WidgetsBinding.instance;
      wb.addObserver(this);
      didChangeAppLifecycleState(wb.lifecycleState);
    }
  }
  bool background = false;
  bool speakerOn = false;
  late VoIP voip;
  OverlayEntry? overlayEntry;
  BuildContext get context => matrix.context;

  @override
  void didChangeAppLifecycleState(AppLifecycleState? state) {
    background = (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused);
  }

  void addCallingOverlay(String callId, CallSession call) {
    final navigatorContext = SimpleMessengerApp.router.routerDelegate.navigatorKey.currentContext ?? context;

    showDialog(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (context) => Calling(
        context: context,
        client: client,
        callId: callId,
        call: call,
        onClear: () => Navigator.of(context).pop(),
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

  Future<bool> get hasCallingAccount async => false;

  @override
  Future<void> playRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().startRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> stopRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().stopRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> handleNewCall(CallSession call) async {
    try {
      // Register listeners first
      await registerListeners(call);
      
      if (PlatformInfos.isAndroid) {
        try {
          final wasForeground = await FlutterForegroundTask.isAppOnForeground;

          await matrix.store.setString(
            'wasForeground',
            wasForeground == true ? 'true' : 'false',
          );
          FlutterForegroundTask.setOnLockScreenVisibility(true);
          FlutterForegroundTask.wakeUpScreen();
          FlutterForegroundTask.launchApp();
        } catch (e) {
          Logs().e('VOIP foreground failed $e');
        }
      }
      
      // Add calling overlay
      addCallingOverlay(call.callId, call);
      
    } catch (e) {
      Logs().e('Failed to handle new call: $e');
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Что-то пошло не так при инициации звонка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    if (PlatformInfos.isAndroid) {
      try {
        FlutterForegroundTask.setOnLockScreenVisibility(false);
        FlutterForegroundTask.stopService();
        final wasForeground = matrix.store.getString('wasForeground');
        if (wasForeground == 'false') FlutterForegroundTask.minimizeApp();
      } catch (e) {
        Logs().e('Failed to handle Android cleanup: $e');
      }
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
  // TODO: implement canHandleNewCall
  bool get canHandleNewCall =>
      voip.currentCID == null && voip.currentGroupCID == null;

  @override
  Future<void> handleMissedCall(CallSession session) async {
    // TODO: implement handleMissedCall
  }

  @override
  EncryptionKeyProvider? get keyProvider => null;

  @override
  Future<void> registerListeners(CallSession session) async {
    // Basic implementation for call listeners
    session.onCallStateChanged.stream.listen((state) {
      Logs().d('Call state changed: $state');
    });
    
    session.onCallEventChanged.stream.listen((event) {
      Logs().d('Call event changed: $event');
    });
  }
}
