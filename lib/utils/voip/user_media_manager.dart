import 'package:just_audio/just_audio.dart';

class UserMediaManager {
  factory UserMediaManager() {
    return _instance;
  }

  UserMediaManager._internal();

  static final UserMediaManager _instance = UserMediaManager._internal();

  AudioPlayer? _assetsAudioPlayer;

  Future<void> startRingingTone() async {
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
        // If both fail, just log the error
        print('Failed to play ringtone: $e2');
      }
    }
  }

  Future<void> stopRingingTone() async {
    await _assetsAudioPlayer?.stop();
    _assetsAudioPlayer = null;
    return;
  }
}
