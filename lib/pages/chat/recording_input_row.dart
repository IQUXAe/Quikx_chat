import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:quikxchat/config/env_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat/recording_view_model.dart';
import 'package:quikxchat/widgets/matrix.dart';

class RecordingInputRow extends StatelessWidget {
  final RecordingViewModelState state;
  final Future<void> Function(String, int, List<int>, String?) onSend;
  final void Function(String) onSendText;
  const RecordingInputRow({
    required this.state,
    required this.onSend,
    required this.onSendText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = Matrix.of(context).store;
    final aiEnabled = AppSettings.aiEnabled.getItem(store);
    final voiceToTextEnabled = AppSettings.voiceToTextEnabled.getItem(store);
    final configValid = EnvConfig.v2tServerUrl.isNotEmpty && EnvConfig.v2tSecretKey.isNotEmpty;
    final showV2TButton = !kIsWeb && configValid && aiEnabled && voiceToTextEnabled; // Security: API key exposed in web
    const maxDecibalWidth = 36.0;
    final time =
        '${state.duration.inMinutes.toString().padLeft(2, '0')}:${(state.duration.inSeconds % 60).toString().padLeft(2, '0')}';
    return Row(
      children: [
        IconButton(
          tooltip: L10n.of(context).cancel,
          icon: const Icon(Icons.close_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: state.cancel,
        ),
        if (state.isPaused)
          IconButton(
            tooltip: 'Resume',
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: state.resume,
          )
        else
          IconButton(
            tooltip: 'Pause',
            icon: const Icon(Icons.pause_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: state.pause,
          ),
        Text(time),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const width = 4;
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: state.amplitudeTimeline.reversed
                    .take((constraints.maxWidth / (width + 2)).floor())
                    .toList()
                    .reversed
                    .map(
                      (amplitude) => Container(
                        margin: const EdgeInsets.only(left: 2),
                        width: width.toDouble(),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        height: maxDecibalWidth * (amplitude / 100),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        if (showV2TButton)
          IconButton(
            style: IconButton.styleFrom(
              disabledBackgroundColor: theme.colorScheme.secondaryContainer.withAlpha(128),
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            tooltip: 'Voice to text',
            icon: state.isSending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Icon(Icons.text_fields, size: 20),
            onPressed: state.isSending ? null : () {
              state.stopAndConvertToText((text) {
                onSendText(text);
              });
            },
          ),
        IconButton(
          style: IconButton.styleFrom(
            disabledBackgroundColor: theme.colorScheme.primary.withAlpha(128),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          tooltip: L10n.of(context).sendAudio,
          icon: state.isSending
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 20),
          onPressed: state.isSending ? null : () => state.stopAndSend(onSend),
        ),
      ],
    );
  }
}