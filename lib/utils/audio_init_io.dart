import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:matrix/matrix.dart';

bool initAudio() {
  try {
    try {
      final libc = DynamicLibrary.open('libc.so.6');
      final setlocale = libc.lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)
      >('setlocale');
      const lcAll = 6;
      setlocale(lcAll, 'C'.toNativeUtf8());
    } catch (_) {}
    
    JustAudioMediaKit.ensureInitialized(linux: true, windows: false);
    Logs().i('media_kit initialized. Audio playback enabled.');
    return true;
  } catch (e) {
    Logs().w('media_kit failed (mpv not installed). Audio disabled.', e);
    return false;
  }
}
