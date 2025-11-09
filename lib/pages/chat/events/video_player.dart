import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/utils/date_time_extension.dart';
import 'package:quikxchat/utils/file_description.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/utils/url_launcher.dart';
import 'package:quikxchat/widgets/blur_hash.dart';
import 'package:quikxchat/widgets/mxc_image.dart';
import '../../image_viewer/image_viewer.dart';

class EventVideoPlayer extends StatelessWidget {
  final Event event;
  final Timeline? timeline;
  final Color? textColor;
  final Color? linkColor;

  const EventVideoPlayer(
    this.event, {
    this.timeline,
    this.textColor,
    this.linkColor,
    super.key,
  });

  static const String fallbackBlurHash = 'L5H2EC=PM+yV0g-mq.wG9c010J}I';

  @override
  Widget build(BuildContext context) {
    final supportsVideoPlayer = PlatformInfos.supportsVideoPlayer;

    final blurHash = (event.infoMap as Map<String, dynamic>)
            .tryGet<String>('xyz.amorgan.blurhash') ??
        fallbackBlurHash;
    final fileDescription = event.fileDescription;
    const maxDimension = 300.0;
    final infoMap = event.content.tryGetMap<String, Object?>('info');
    final videoWidth = infoMap?.tryGet<int>('w') ?? maxDimension;
    final videoHeight = infoMap?.tryGet<int>('h') ?? maxDimension;

    final modifier = max(videoWidth, videoHeight) / maxDimension;
    final width = videoWidth / modifier;
    final height = videoHeight / modifier;

    final durationInt = infoMap?.tryGet<int>('duration');
    final duration =
        durationInt == null ? null : Duration(milliseconds: durationInt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          child: InkWell(
            onTap: () => supportsVideoPlayer
                ? showDialog(
                    context: context,
                    builder: (_) => ImageViewer(
                      event,
                      timeline: timeline,
                      outerContext: context,
                    ),
                  )
                : event.saveFile(context),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            child: SizedBox(
              width: width,
              height: height,
              child: Hero(
                tag: event.eventId,
                child: Stack(
                  children: [
                    if (event.hasThumbnail)
                      MxcImage(
                        event: event,
                        isThumbnail: true,
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                        placeholder: (context) => BlurHash(
                          blurhash: blurHash,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      BlurHash(
                        blurhash: blurHash,
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                      ),
                    Center(
                      child: CircleAvatar(
                        child: supportsVideoPlayer
                            ? const Icon(Icons.play_arrow_outlined)
                            : const Icon(Icons.file_download_outlined),
                      ),
                    ),
                    if (duration != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.originServerTs.localizedTimeShort(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (fileDescription != null && textColor != null && linkColor != null)
          SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Linkify(
                text: fileDescription,
                textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
                style: TextStyle(
                  color: textColor,
                  fontSize:
                      AppConfig.fontSizeFactor * AppConfig.messageFontSize,
                ),
                options: const LinkifyOptions(humanize: false),
                linkStyle: TextStyle(
                  color: linkColor,
                  fontSize:
                      AppConfig.fontSizeFactor * AppConfig.messageFontSize,
                  decoration: TextDecoration.underline,
                  decorationColor: linkColor,
                ),
                onOpen: (url) => UrlLauncher(context, url.url).launchUrl(),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '00:${duration.inSeconds.toString().padLeft(2, '0')}';
    }
  }
}
