import 'dart:io';

import 'package:flutter/foundation.dart';


import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';

class UserMediaManager {
  factory UserMediaManager() {
    return _instance;
  }

  UserMediaManager._internal();

  static final UserMediaManager _instance = UserMediaManager._internal();

  AudioPlayer? _assetsAudioPlayer;
  AudioSession? _audioSession;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _audioSession = await AudioSession.instance;
        await _audioSession!.configure(const AudioSessionConfiguration.speech());
      }
      
      _isInitialized = true;
    } catch (e) {
      Logs().e('Failed to initialize UserMediaManager: $e');
    }
  }

  Future<void> startRingingTone() async {
    await _initialize();
    
    try {
      // Use just_audio for all platforms
      await _playRingtoneWithAudio();
    } catch (e) {
      Logs().e('Failed to play ringtone: $e');
      // Fallback to system sound
      // Fallback sound
    }
  }

  Future<void> _playRingtoneWithAudio() async {
    try {
      const path = 'assets/sounds/phone.ogg';
      final player = _assetsAudioPlayer = AudioPlayer();
      await player.setAsset(path);
      await player.setLoopMode(LoopMode.all);
      await player.play();
    } catch (e) {
      // Fallback - try different audio file
      try {
        const fallbackPath = 'assets/sounds/call.ogg';
        final player = _assetsAudioPlayer = AudioPlayer();
        await player.setAsset(fallbackPath);
        await player.setLoopMode(LoopMode.all);
        await player.play();
      } catch (e2) {
        Logs().e('Ringtone playback failed: $e2');
      }
    }
  }

  Future<void> stopRingingTone() async {
    try {
      await _assetsAudioPlayer?.stop();
      _assetsAudioPlayer = null;
    } catch (e) {
      Logs().e('Failed to stop ringtone: $e');
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _audioSession?.setActive(true);
        // This will be handled by the WebRTC plugin
      }
    } catch (e) {
      Logs().e('Failed to set speakerphone: $e');
    }
  }

  void dispose() {
    _assetsAudioPlayer?.dispose();
    _audioSession?.setActive(false);
  }
}