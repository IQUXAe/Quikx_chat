import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/env_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/utils/error_reporter.dart';
import 'package:quikxchat/utils/file_description.dart';
import 'package:quikxchat/utils/localized_exception_extension.dart';
import 'package:quikxchat/utils/url_launcher.dart';
import 'package:quikxchat/utils/date_time_extension.dart';
import 'package:quikxchat/utils/voice_to_text_client.dart';
import '../../../utils/matrix_sdk_extensions/event_extension.dart';
import '../../../widgets/quikx_chat_app.dart';
import '../../../widgets/matrix.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Color color;
  final Color linkColor;
  final double fontSize;
  final Event event;
  final Timeline? timeline;

  static const int wavesCount = 40;

  const AudioPlayerWidget(
    this.event, {
    required this.color,
    required this.linkColor,
    required this.fontSize,
    this.timeline,
    super.key,
  });

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

enum AudioPlayerStatus { notDownloaded, downloading, downloaded }

class AudioPlayerState extends State<AudioPlayerWidget> {
  static const double buttonSize = 36;

  AudioPlayerStatus status = AudioPlayerStatus.notDownloaded;
  double? _downloadProgress;

  late final MatrixState matrix;
  List<int>? _waveform;
  String? _durationString;
  bool _isTranscribing = false;
  String? _transcribedText;
  bool _showTranscription = false;
  double _lastPosition = 0.0;
  bool _isSeeking = false;
  
  static final Map<String, String> _transcriptionCache = {};

  @override
  void dispose() {
    super.dispose();
    final audioPlayer = matrix.voiceMessageEventId.value != widget.event.eventId
        ? null
        : matrix.audioPlayer;
    if (audioPlayer != null) {
      if (audioPlayer.playing && !audioPlayer.isAtEndPosition) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(matrix.context).showMaterialBanner(
            MaterialBanner(
              padding: EdgeInsets.zero,
              leading: StreamBuilder(
                stream: audioPlayer.playerStateStream.asBroadcastStream(),
                builder: (context, _) => IconButton(
                  onPressed: () {
                    if (audioPlayer.isAtEndPosition) {
                      audioPlayer.seek(Duration.zero);
                    } else if (audioPlayer.playing) {
                      audioPlayer.pause();
                    } else {
                      audioPlayer.play();
                    }
                  },
                  icon: audioPlayer.playing && !audioPlayer.isAtEndPosition
                      ? const Icon(Icons.pause_outlined)
                      : const Icon(Icons.play_arrow_outlined),
                ),
              ),
              content: StreamBuilder(
                stream: audioPlayer.positionStream.asBroadcastStream(),
                builder: (context, _) => GestureDetector(
                  onTap: () => QuikxChatApp.router.go(
                    '/rooms/${widget.event.room.id}?event=${widget.event.eventId}',
                  ),
                  child: Text(
                    '🎙️ ${audioPlayer.position.minuteSecondString} / ${audioPlayer.duration?.minuteSecondString} - ${widget.event.senderFromMemoryOrFallback.calcDisplayname()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    audioPlayer.pause();
                    audioPlayer.dispose();
                    matrix.voiceMessageEventId.value =
                        matrix.audioPlayer = null;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(matrix.context)
                          .clearMaterialBanners();
                    });
                  },
                  icon: const Icon(Icons.close_outlined),
                ),
              ],
            ),
          );
        });
        return;
      }
      audioPlayer.pause();
      audioPlayer.dispose();
      matrix.voiceMessageEventId.value = matrix.audioPlayer = null;
    }
  }

  void _onButtonTap() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(matrix.context).clearMaterialBanners();
    });
    final currentPlayer =
        matrix.voiceMessageEventId.value != widget.event.eventId
            ? null
            : matrix.audioPlayer;
    if (currentPlayer != null) {
      if (currentPlayer.isAtEndPosition) {
        currentPlayer.seek(Duration.zero);
      } else if (currentPlayer.playing) {
        currentPlayer.pause();
      } else {
        currentPlayer.play();
      }
      return;
    }

    matrix.voiceMessageEventId.value = widget.event.eventId;
    matrix.audioPlayer
      ?..stop()
      ..dispose();
    File? file;
    MatrixFile? matrixFile;

    setState(() => status = AudioPlayerStatus.downloading);
    try {
      final fileSize = widget.event.content
          .tryGetMap<String, dynamic>('info')
          ?.tryGet<int>('size');
      matrixFile = await widget.event.downloadAndDecryptAttachment(
        onDownloadProgress: fileSize != null && fileSize > 0
            ? (progress) {
                final progressPercentage = progress / fileSize;
                setState(() {
                  _downloadProgress =
                      progressPercentage < 1 ? progressPercentage : null;
                });
              }
            : null,
      );

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.encodeComponent(
          widget.event.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
        );
        file = File('${tempDir.path}/${fileName}_${matrixFile.name}');

        await file.writeAsBytes(matrixFile.bytes);
      }

      setState(() {
        status = AudioPlayerStatus.downloaded;
      });
    } catch (e, s) {
      Logs().v('Could not download audio file', e, s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toLocalizedString(context)),
        ),
      );
      rethrow;
    }
    if (!context.mounted) return;
    if (matrix.voiceMessageEventId.value != widget.event.eventId) return;

    final audioPlayer = matrix.audioPlayer = AudioPlayer();

    if (file != null) {
      audioPlayer.setFilePath(file.path);
    } else {
      await audioPlayer.setAudioSource(MatrixFileAudioSource(matrixFile));
    }

    audioPlayer.play().onError(
          ErrorReporter(context, 'Unable to play audio message')
              .onErrorCallback,
        );
  }

  void _toggleSpeed() async {
    final audioPlayer = matrix.audioPlayer;
    if (audioPlayer == null) return;
    switch (audioPlayer.speed) {
      case 1.0:
        await audioPlayer.setSpeed(1.25);
        break;
      case 1.25:
        await audioPlayer.setSpeed(1.5);
        break;
      case 1.5:
        await audioPlayer.setSpeed(2.0);
        break;
      case 2.0:
        await audioPlayer.setSpeed(0.5);
        break;
      case 0.5:
      default:
        await audioPlayer.setSpeed(1.0);
        break;
    }
    setState(() {});
  }

  bool _isAIEnabled() {
    if (EnvConfig.v2tServerUrl.isEmpty || EnvConfig.v2tSecretKey.isEmpty) {
      return false;
    }
    final store = matrix.store;
    final aiEnabled = AppSettings.aiEnabled.getItem(store);
    final voiceToTextEnabled = AppSettings.voiceToTextEnabled.getItem(store);
    return aiEnabled && voiceToTextEnabled;
  }

  void _transcribeAudio() async {
    if (!_isAIEnabled()) return;
    
    final eventId = widget.event.eventId;
    
    // Если уже есть перевод - переключаем видимость с анимацией
    if (_transcribedText != null) {
      if (_showTranscription) {
        setState(() => _showTranscription = false);
      } else {
        setState(() => _showTranscription = true);
      }
      return;
    }
    
    // Проверяем кэш
    if (_transcriptionCache.containsKey(eventId)) {
      setState(() {
        _transcribedText = _transcriptionCache[eventId];
        _showTranscription = true;
      });
      return;
    }
    
    if (_isTranscribing) return;
    
    setState(() => _isTranscribing = true);
    
    try {
      final matrixFile = await widget.event.downloadAndDecryptAttachment();
      
      File? file;
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.encodeComponent(
          widget.event.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
        );
        file = File('${tempDir.path}/${fileName}_${matrixFile.name}');
        await file.writeAsBytes(matrixFile.bytes);
      }
      
      if (file == null) {
        throw Exception('Web platform not supported for transcription');
      }
      
      final text = await VoiceToTextClient.convert(file.path);
      
      setState(() {
        _transcribedText = text;
        _transcriptionCache[eventId] = text;
        _showTranscription = true;
        _isTranscribing = false;
      });
    } catch (e, s) {
      Logs().e('Failed to transcribe audio', e, s);
      setState(() => _isTranscribing = false);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка перевода: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<int>? _getWaveform() {
    final eventWaveForm = widget.event.content
        .tryGetMap<String, dynamic>('org.matrix.msc1767.audio')
        ?.tryGetList<int>('waveform');
    if (eventWaveForm == null || eventWaveForm.isEmpty) {
      return null;
    }
    while (eventWaveForm.length < AudioPlayerWidget.wavesCount) {
      for (var i = 0; i < eventWaveForm.length; i = i + 2) {
        eventWaveForm.insert(i, eventWaveForm[i]);
      }
    }
    var i = 0;
    final step = (eventWaveForm.length / AudioPlayerWidget.wavesCount).round();
    while (eventWaveForm.length > AudioPlayerWidget.wavesCount) {
      eventWaveForm.removeAt(i);
      i = (i + step) % AudioPlayerWidget.wavesCount;
    }
    return eventWaveForm.map((i) => i > 1024 ? 1024 : i).toList();
  }

  @override
  void initState() {
    super.initState();
    matrix = Matrix.of(context);
    _waveform = _getWaveform();

    if (matrix.voiceMessageEventId.value == widget.event.eventId &&
        matrix.audioPlayer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(matrix.context).clearMaterialBanners();
      });
    }

    final durationInt = widget.event.content
        .tryGetMap<String, dynamic>('info')
        ?.tryGet<int>('duration');
    if (durationInt != null) {
      final duration = Duration(milliseconds: durationInt);
      _durationString = duration.minuteSecondString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waveform = _waveform;

    return ValueListenableBuilder(
      valueListenable: matrix.voiceMessageEventId,
      builder: (context, eventId, _) {
        final audioPlayer =
            eventId != widget.event.eventId ? null : matrix.audioPlayer;

        final fileDescription = widget.event.fileDescription;

        return StreamBuilder<Duration>(
          stream: audioPlayer?.positionStream,
          builder: (context, positionSnapshot) {
            final maxPosition =
                audioPlayer?.duration?.inMilliseconds.toDouble() ?? 1.0;
            var currentPosition = positionSnapshot.data?.inMilliseconds.toDouble() ??
                audioPlayer?.position.inMilliseconds.toDouble() ?? 0.0;
            
            // Предотвращаем подергивание назад (только если не seek)
            if (!_isSeeking && audioPlayer != null && currentPosition < _lastPosition) {
              final diff = _lastPosition - currentPosition;
              // Игнорируем скачки назад меньше 2 секунд
              if (diff < 2000) {
                currentPosition = _lastPosition;
              } else {
                _lastPosition = currentPosition;
              }
            } else {
              _lastPosition = currentPosition;
            }
            
            if (currentPosition > maxPosition) currentPosition = maxPosition;

            final wavePosition =
                (currentPosition / maxPosition) * AudioPlayerWidget.wavesCount;

            final statusText = audioPlayer == null
                ? _durationString ?? '00:00'
                : (positionSnapshot.data ?? audioPlayer.position).minuteSecondString;
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: status == AudioPlayerStatus.downloading
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: widget.color,
                                  value: _downloadProgress,
                                )
                              : StreamBuilder<PlayerState>(
                                  stream: audioPlayer?.playerStateStream,
                                  builder: (context, stateSnapshot) {
                                    final isPlaying = stateSnapshot.data?.playing ?? audioPlayer?.playing ?? false;
                                    final isAtEnd = audioPlayer?.isAtEndPosition ?? false;
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(64),
                                      onLongPress: () =>
                                          widget.event.saveFile(context),
                                      onTap: _onButtonTap,
                                      child: Material(
                                        color: widget.color.withAlpha(64),
                                        borderRadius: BorderRadius.circular(64),
                                        child: Icon(
                                          isPlaying && !isAtEnd
                                              ? Icons.pause_outlined
                                              : Icons.play_arrow_outlined,
                                          color: widget.color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              if (waveform != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      for (var i = 0;
                                          i < AudioPlayerWidget.wavesCount;
                                          i++)
                                        Expanded(
                                          child: Container(
                                            height: 32,
                                            alignment: Alignment.center,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: i < wavePosition
                                                    ? widget.color
                                                    : widget.color
                                                        .withAlpha(128),
                                                borderRadius:
                                                    BorderRadius.circular(64),
                                              ),
                                              height: 32 * (waveform[i] / 1024),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                height: 32,
                                child: Slider(
                                  thumbColor: widget.event.senderId ==
                                          widget.event.room.client.userID
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                  activeColor: waveform == null
                                      ? widget.color
                                      : Colors.transparent,
                                  inactiveColor: waveform == null
                                      ? widget.color.withAlpha(128)
                                      : Colors.transparent,
                                  max: maxPosition,
                                  value: currentPosition,
                                  onChanged: (position) {
                                    if (audioPlayer == null) {
                                      _onButtonTap();
                                    } else {
                                      _isSeeking = true;
                                      _lastPosition = position;
                                      audioPlayer.seek(
                                        Duration(milliseconds: position.round()),
                                      ).then((_) {
                                        Future.delayed(const Duration(milliseconds: 100), () {
                                          _isSeeking = false;
                                        });
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: widget.color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              widget.event.originServerTs.localizedTimeShort(context),
                              style: TextStyle(
                                color: widget.color.withAlpha(180),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                        if (_isAIEnabled()) ...[
                          const SizedBox(width: 8),
                          Material(
                            color: widget.color.withAlpha(64),
                            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                              onTap: _transcribeAudio,
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: _isTranscribing
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: widget.color,
                                        ),
                                      )
                                    : Icon(
                                        Icons.text_fields,
                                        color: widget.color,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        AnimatedCrossFade(
                          firstChild: Icon(
                            Icons.mic_none_outlined,
                            color: widget.color,
                          ),
                          secondChild: Material(
                            color: widget.color.withAlpha(64),
                            borderRadius:
                                BorderRadius.circular(AppConfig.borderRadius),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppConfig.borderRadius),
                              onTap: _toggleSpeed,
                              child: SizedBox(
                                width: 32,
                                height: 20,
                                child: Center(
                                  child: Text(
                                    '${audioPlayer?.speed.toString()}x',
                                    style: TextStyle(
                                      color: widget.color,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          crossFadeState: audioPlayer == null
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: QuikxChatThemes.animationDuration,
                        ),
                      ],
                    ),
                  AnimatedSize(
                    duration: QuikxChatThemes.animationDuration,
                    curve: Curves.easeInOut,
                    child: _transcribedText != null
                        ? AnimatedOpacity(
                            opacity: _showTranscription ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _showTranscription
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: widget.color.withAlpha(32),
                                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                                      ),
                                      child: SelectableText(
                                        _transcribedText!,
                                        style: TextStyle(
                                          color: widget.color,
                                          fontSize: widget.fontSize,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (fileDescription != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Linkify(
                        text: fileDescription,
                        textScaleFactor:
                            MediaQuery.textScalerOf(context).scale(1),
                        style: TextStyle(
                          color: widget.color,
                          fontSize: widget.fontSize,
                        ),
                        options: const LinkifyOptions(humanize: false),
                        linkStyle: TextStyle(
                          color: widget.linkColor,
                          fontSize: widget.fontSize,
                          decoration: TextDecoration.underline,
                          decorationColor: widget.linkColor,
                        ),
                        onOpen: (url) =>
                            UrlLauncher(context, url.url).launchUrl(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// To use a MatrixFile as an AudioSource for the just_audio package
class MatrixFileAudioSource extends StreamAudioSource {
  final MatrixFile file;

  MatrixFileAudioSource(this.file);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= file.bytes.length;
    return StreamAudioResponse(
      sourceLength: file.bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(file.bytes.sublist(start, end)),
      contentType: file.mimeType,
    );
  }
}

extension on AudioPlayer {
  bool get isAtEndPosition {
    final duration = this.duration;
    if (duration == null) return true;
    // Считаем что достигли конца если осталось меньше 100мс
    return position >= duration - const Duration(milliseconds: 100);
  }
}

extension on Duration {
  String get minuteSecondString =>
      '${inMinutes.toString().padLeft(2, '0')}:${(inSeconds % 60).toString().padLeft(2, '0')}';
}
