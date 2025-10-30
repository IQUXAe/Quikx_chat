import 'package:flutter/material.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/utils/file_description.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:quikxchat/utils/url_launcher.dart';
import 'package:quikxchat/utils/date_time_extension.dart';

class MessageDownloadContent extends StatefulWidget {
  final Event event;
  final Color textColor;
  final Color linkColor;

  const MessageDownloadContent(
    this.event, {
    required this.textColor,
    required this.linkColor,
    super.key,
  });

  @override
  State<MessageDownloadContent> createState() => _MessageDownloadContentState();
}

class _MessageDownloadContentState extends State<MessageDownloadContent> {
  double? _downloadProgress;
  bool _isDownloading = false;

  Future<void> _downloadFile() async {
    if (_isDownloading) return;
    
    setState(() => _isDownloading = true);
    
    try {
      final fileSize = widget.event.content
          .tryGetMap<String, dynamic>('info')
          ?.tryGet<int>('size');
      
      await widget.event.downloadAndDecryptAttachment(
        getThumbnail: false,
        onDownloadProgress: fileSize != null && fileSize > 0
            ? (progress) {
                if (mounted) {
                  setState(() {
                    _downloadProgress = progress / fileSize;
                  });
                }
              }
            : null,
      );
      
      if (mounted) {
        widget.event.saveFile(context);
      }
    } catch (e) {
      Logs().e('Download error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.event.content.tryGet<String>('filename') ?? widget.event.body;
    final filetype = (filename.contains('.')
        ? filename.split('.').last.toUpperCase()
        : widget.event.content
                .tryGetMap<String, dynamic>('info')
                ?.tryGet<String>('mimetype')
                ?.toUpperCase() ??
            'UNKNOWN');
    final sizeString = widget.event.sizeString ?? '?MB';
    final fileDescription = widget.event.fileDescription;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
            onTap: _isDownloading ? null : _downloadFile,
            child: Stack(
              children: [
                Container(
                  width: 400,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: _isDownloading
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _downloadProgress,
                                    strokeWidth: 3,
                                    color: widget.textColor,
                                  ),
                                  if (_downloadProgress != null)
                                    Text(
                                      '${(_downloadProgress! * 100).toInt()}%',
                                      style: TextStyle(
                                        color: widget.textColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              )
                            : CircleAvatar(
                                backgroundColor: widget.textColor.withAlpha(32),
                                child: Icon(Icons.file_download_outlined, color: widget.textColor),
                              ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$sizeString | $filetype',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: widget.textColor, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Text(
                    widget.event.originServerTs.localizedTimeShort(context),
                    style: TextStyle(
                      color: widget.textColor.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (fileDescription != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Linkify(
              text: fileDescription,
              textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
              style: TextStyle(
                color: widget.textColor,
                fontSize: AppConfig.fontSizeFactor * AppConfig.messageFontSize,
              ),
              options: const LinkifyOptions(humanize: false),
              linkStyle: TextStyle(
                color: widget.linkColor,
                fontSize: AppConfig.fontSizeFactor * AppConfig.messageFontSize,
                decoration: TextDecoration.underline,
                decorationColor: widget.linkColor,
              ),
              onOpen: (url) => UrlLauncher(context, url.url).launchUrl(),
            ),
          ),
        ],
      ],
    );
  }
}
