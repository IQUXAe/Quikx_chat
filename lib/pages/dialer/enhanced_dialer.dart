import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:matrix/matrix.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:simplemessenger/utils/platform_infos.dart';
import 'package:simplemessenger/utils/voip/video_renderer.dart';
import 'package:simplemessenger/widgets/avatar.dart';
import 'pip/pip_view.dart';

class EnhancedCalling extends StatefulWidget {
  final VoidCallback? onClear;
  final BuildContext context;
  final String callId;
  final CallSession call;
  final Client client;

  const EnhancedCalling({
    required this.context,
    required this.call,
    required this.client,
    required this.callId,
    this.onClear,
    super.key,
  });

  @override
  EnhancedCallingState createState() => EnhancedCallingState();
}

class EnhancedCallingState extends State<EnhancedCalling>
    with TickerProviderStateMixin {
  Room? get room => call.room;
  String get displayName => call.room.getLocalizedDisplayname(
        MatrixLocals(L10n.of(widget.context)),
      );
  String get callId => widget.callId;
  CallSession get call => widget.call;

  bool get isMicrophoneMuted => call.isMicrophoneMuted;
  bool get isLocalVideoMuted => call.isLocalVideoMuted;
  bool get isScreensharingEnabled => call.screensharingEnabled;
  bool get isRemoteOnHold => call.remoteOnHold;
  bool get voiceonly => call.type == CallType.kVoice;
  bool get connecting => call.state == CallState.kConnecting;
  bool get connected => call.state == CallState.kConnected;

  double? _localVideoHeight;
  double? _localVideoWidth;
  EdgeInsetsGeometry? _localVideoMargin;
  CallState? _state;
  bool _speakerOn = false;
  AudioSession? _audioSession;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudio();
    _initialize();
    _startCallTimer();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (!connected) {
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _initializeAudio() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _audioSession = await AudioSession.instance;
        await _audioSession!.configure(const AudioSessionConfiguration.speech());
      }
    } catch (e) {
      Logs().e('Failed to initialize audio session: $e');
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (connected) {
        setState(() {
          _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _initialize() async {
    final call = this.call;
    call.onCallStateChanged.stream.listen(_handleCallState);
    call.onCallEventChanged.stream.listen((event) {
      if (event == CallStateChange.kFeedsChanged) {
        setState(() {
          call.tryRemoveStopedStreams();
        });
      } else if (event == CallStateChange.kLocalHoldUnhold ||
          event == CallStateChange.kRemoteHoldUnhold) {
        setState(() {});
        Logs().i(
          'Call hold event: local ${call.localHold}, remote ${call.remoteOnHold}',
        );
      }
    });
    _state = call.state;

    if (call.type == CallType.kVideo) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }
  }

  void _cleanUp() {
    _callTimer?.cancel();
    if (!_pulseController.isDisposed) {
      _pulseController.dispose();
    }
    Timer(
      const Duration(seconds: 2),
      () => widget.onClear?.call(),
    );
    if (call.type == CallType.kVideo) {
      try {
        WakelockPlus.disable();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    if (!_pulseController.isDisposed) {
      _pulseController.dispose();
    }
    try {
      _audioSession?.setActive(false);
    } catch (_) {}
    super.dispose();
    try {
      call.cleanUp.call();
    } catch (_) {}
  }

  void _resizeLocalVideo(Orientation orientation) {
    final shortSide = min(
      MediaQuery.sizeOf(widget.context).width,
      MediaQuery.sizeOf(widget.context).height,
    );
    _localVideoMargin = call.getRemoteStreams.isNotEmpty
        ? const EdgeInsets.only(top: 20.0, right: 20.0)
        : EdgeInsets.zero;
    _localVideoWidth = call.getRemoteStreams.isNotEmpty
        ? shortSide / 3
        : MediaQuery.sizeOf(widget.context).width;
    _localVideoHeight = call.getRemoteStreams.isNotEmpty
        ? shortSide / 4
        : MediaQuery.sizeOf(widget.context).height;
  }

  void _handleCallState(CallState state) {
    Logs().v('EnhancedCalling::handleCallState: ${state.toString()}');
    
    if ({CallState.kConnected, CallState.kEnded}.contains(state)) {
      HapticFeedback.heavyImpact();
    }

    if (state == CallState.kConnected) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (mounted) {
      setState(() {
        _state = state;
        if (_state == CallState.kEnded) _cleanUp();
      });
    }
  }

  void _answerCall() {
    setState(() {
      call.answer();
    });
  }

  void _hangUp() {
    setState(() {
      if (call.isRinging) {
        call.reject();
      } else {
        call.hangup(reason: CallErrorCode.userHangup);
      }
    });
  }

  void _muteMic() {
    setState(() {
      call.setMicrophoneMuted(!call.isMicrophoneMuted);
    });
    HapticFeedback.lightImpact();
  }

  void _muteCamera() {
    setState(() {
      call.setLocalVideoMuted(!call.isLocalVideoMuted);
    });
    HapticFeedback.lightImpact();
  }

  void _switchCamera() async {
    if (call.localUserMediaStream != null) {
      await Helper.switchCamera(
        call.localUserMediaStream!.stream!.getVideoTracks()[0],
      );
    }
    setState(() {});
    HapticFeedback.lightImpact();
  }

  void _toggleSpeaker() async {
    if (mounted) {
      setState(() {
        _speakerOn = !_speakerOn;
      });
    }
    
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Helper.setSpeakerphoneOn(_speakerOn);
      }
    } catch (e) {
      Logs().e('Failed to toggle speaker: $e');
    }
    
    if (mounted) {
      HapticFeedback.lightImpact();
    }
  }

  void _screenSharing() async {
    if (PlatformInfos.isAndroid) {
      if (!call.screensharingEnabled) {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'screen_sharing_channel',
            channelName: 'Screen Sharing',
            channelDescription: L10n.of(widget.context).foregroundServiceRunning,
          ),
          iosNotificationOptions: const IOSNotificationOptions(),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.nothing(),
          ),
        );
        FlutterForegroundTask.startService(
          notificationTitle: L10n.of(widget.context).screenSharingTitle,
          notificationText: L10n.of(widget.context).screenSharingDetail,
        );
      } else {
        FlutterForegroundTask.stopService();
      }
    }

    setState(() {
      call.setScreensharingEnabled(!call.screensharingEnabled);
    });
    HapticFeedback.lightImpact();
  }

  void _remoteOnHold() {
    setState(() {
      call.setRemoteOnHold(!call.remoteOnHold);
    });
    HapticFeedback.lightImpact();
  }

  Widget _buildCallButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    Color? foregroundColor,
    String? tooltip,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? backgroundColor : Colors.grey,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: enabled ? onPressed : null,
            child: Icon(
              icon,
              color: foregroundColor ?? Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(bool isFloating) {
    if (isFloating) return [];

    final buttons = <Widget>[];

    switch (_state) {
      case CallState.kRinging:
      case CallState.kInviteSent:
      case CallState.kCreateAnswer:
      case CallState.kConnecting:
        if (call.isOutgoing) {
          buttons.add(_buildCallButton(
            icon: Icons.call_end,
            onPressed: _hangUp,
            backgroundColor: Colors.red,
            tooltip: 'Завершить звонок',
          ));
        } else {
          buttons.addAll([
            _buildCallButton(
              icon: Icons.call,
              onPressed: _answerCall,
              backgroundColor: Colors.green,
              tooltip: 'Принять звонок',
            ),
            const SizedBox(width: 20),
            _buildCallButton(
              icon: Icons.call_end,
              onPressed: _hangUp,
              backgroundColor: Colors.red,
              tooltip: 'Отклонить звонок',
            ),
          ]);
        }
        break;
        
      case CallState.kConnected:
        buttons.addAll([
          _buildCallButton(
            icon: isMicrophoneMuted ? Icons.mic_off : Icons.mic,
            onPressed: _muteMic,
            backgroundColor: isMicrophoneMuted ? Colors.red : Colors.black45,
            tooltip: isMicrophoneMuted ? 'Включить микрофон' : 'Выключить микрофон',
          ),
          const SizedBox(width: 12),
          
          if (!voiceonly) ...[
            _buildCallButton(
              icon: isLocalVideoMuted ? Icons.videocam_off : Icons.videocam,
              onPressed: _muteCamera,
              backgroundColor: isLocalVideoMuted ? Colors.red : Colors.black45,
              tooltip: isLocalVideoMuted ? 'Включить камеру' : 'Выключить камеру',
            ),
            const SizedBox(width: 12),
          ],
          
          _buildCallButton(
            icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
            onPressed: _toggleSpeaker,
            backgroundColor: _speakerOn ? Colors.blue : Colors.black45,
            tooltip: _speakerOn ? 'Выключить громкую связь' : 'Включить громкую связь',
          ),
          const SizedBox(width: 12),
          
          if (!voiceonly && !kIsWeb) ...[
            _buildCallButton(
              icon: Icons.switch_camera,
              onPressed: _switchCamera,
              backgroundColor: Colors.black45,
              tooltip: 'Переключить камеру',
            ),
            const SizedBox(width: 12),
          ],
          
          if (PlatformInfos.isMobile || PlatformInfos.isWeb) ...[
            _buildCallButton(
              icon: Icons.screen_share,
              onPressed: _screenSharing,
              backgroundColor: isScreensharingEnabled ? Colors.blue : Colors.black45,
              tooltip: isScreensharingEnabled ? 'Остановить демонстрацию экрана' : 'Демонстрация экрана',
            ),
            const SizedBox(width: 12),
          ],
          
          _buildCallButton(
            icon: isRemoteOnHold ? Icons.play_arrow : Icons.pause,
            onPressed: _remoteOnHold,
            backgroundColor: isRemoteOnHold ? Colors.green : Colors.black45,
            tooltip: isRemoteOnHold ? 'Снять с удержания' : 'Поставить на удержание',
          ),
          const SizedBox(width: 12),
          
          _buildCallButton(
            icon: Icons.call_end,
            onPressed: _hangUp,
            backgroundColor: Colors.red,
            tooltip: 'Завершить звонок',
          ),
        ]);
        break;
        
      case CallState.kEnded:
        buttons.add(_buildCallButton(
          icon: Icons.call_end,
          onPressed: _hangUp,
          backgroundColor: Colors.black45,
          enabled: false,
        ));
        break;
        
      default:
        break;
    }

    return buttons;
  }

  Widget _buildStreamView(WrappedMediaStream wrappedStream, {bool mainView = false}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black54,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          VideoRenderer(
            wrappedStream,
            mirror: wrappedStream.isLocal() && 
                   wrappedStream.purpose == SDPStreamMetadataPurpose.Usermedia,
            fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
          if (wrappedStream.videoMuted) ...[ 
            Container(color: Colors.black54),
            Positioned(
              child: Avatar(
                mxContent: wrappedStream.getUser().avatarUrl,
                name: wrappedStream.displayName,
                size: mainView ? 96 : 48,
                client: widget.client,
              ),
            ),
          ],
          if (wrappedStream.purpose != SDPStreamMetadataPurpose.Screenshare)
            Positioned(
              left: 8.0,
              bottom: 8.0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  wrappedStream.audioMuted ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(Orientation orientation, bool isFloating) {
    final stackWidgets = <Widget>[];

    if (call.callHasEnded) {
      return stackWidgets;
    }

    // Show hold state
    if (call.localHold || call.remoteOnHold) {
      var title = '';
      if (call.localHold) {
        title = 'Вы поставили звонок на удержание';
      } else if (call.remoteOnHold) {
        title = '$displayName поставил звонок на удержание';
      }
      
      stackWidgets.add(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pause_circle_filled,
                size: 64.0,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      return stackWidgets;
    }

    // Determine primary stream
    var primaryStream = call.remoteScreenSharingStream ??
        call.localScreenSharingStream ??
        call.remoteUserMediaStream ??
        call.localUserMediaStream;

    if (!connected) {
      primaryStream = call.localUserMediaStream;
    }

    if (primaryStream != null) {
      stackWidgets.add(
        Center(
          child: _buildStreamView(primaryStream, mainView: true),
        ),
      );
    }

    if (isFloating || !connected) {
      return stackWidgets;
    }

    _resizeLocalVideo(orientation);

    if (call.getRemoteStreams.isEmpty) {
      return stackWidgets;
    }

    // Build secondary stream views
    final secondaryStreamViews = <Widget>[];

    if (call.remoteScreenSharingStream != null) {
      final remoteUserMediaStream = call.remoteUserMediaStream;
      if (remoteUserMediaStream != null) {
        secondaryStreamViews.add(
          SizedBox(
            width: _localVideoWidth,
            height: _localVideoHeight,
            child: _buildStreamView(remoteUserMediaStream),
          ),
        );
        secondaryStreamViews.add(const SizedBox(height: 10));
      }
    }

    final localStream = call.localUserMediaStream ?? call.localScreenSharingStream;
    if (localStream != null && !isFloating) {
      secondaryStreamViews.add(
        SizedBox(
          width: _localVideoWidth,
          height: _localVideoHeight,
          child: _buildStreamView(localStream),
        ),
      );
      secondaryStreamViews.add(const SizedBox(height: 10));
    }

    if (call.localScreenSharingStream != null && !isFloating) {
      final remoteUserMediaStream = call.remoteUserMediaStream;
      if (remoteUserMediaStream != null) {
        secondaryStreamViews.add(
          SizedBox(
            width: _localVideoWidth,
            height: _localVideoHeight,
            child: _buildStreamView(remoteUserMediaStream),
          ),
        );
        secondaryStreamViews.add(const SizedBox(height: 10));
      }
    }

    if (secondaryStreamViews.isNotEmpty) {
      stackWidgets.add(
        Container(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 140),
          alignment: Alignment.bottomRight,
          child: Container(
            width: _localVideoWidth,
            margin: _localVideoMargin,
            child: Column(
              children: secondaryStreamViews,
            ),
          ),
        ),
      );
    }

    return stackWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return PIPView(
      builder: (context, isFloating) {
        return Scaffold(
          resizeToAvoidBottomInset: !isFloating,
          body: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
                child: Stack(
                  children: [
                    ..._buildContent(orientation, isFloating),
                    
                    // Top bar with call info
                    if (!isFloating)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            if (!connected)
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Avatar(
                                      mxContent: room?.avatar,
                                      name: displayName,
                                      size: 80,
                                      client: widget.client,
                                    ),
                                  );
                                },
                              )
                            else
                              Avatar(
                                mxContent: room?.avatar,
                                name: displayName,
                                size: 60,
                                client: widget.client,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              connected 
                                  ? _formatDuration(_callDuration)
                                  : _getCallStateText(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Back button for PIP mode
                    if (!isFloating)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
                          onPressed: () {
                            PIPView.of(context)?.setFloating(true);
                          },
                        ),
                      ),
                    
                    // Action buttons
                    if (!isFloating)
                      Positioned(
                        bottom: MediaQuery.of(context).padding.bottom + 40,
                        left: 0,
                        right: 0,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: _buildActionButtons(isFloating),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getCallStateText() {
    switch (_state) {
      case CallState.kRinging:
        return call.isOutgoing ? 'Звоним...' : 'Входящий звонок';
      case CallState.kInviteSent:
        return 'Приглашение отправлено...';
      case CallState.kConnecting:
        return 'Соединение...';
      case CallState.kConnected:
        return 'Подключено';
      case CallState.kEnded:
        return 'Звонок завершен';
      default:
        return 'Инициализация...';
    }
  }
}