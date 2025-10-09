import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:quikxchat/utils/url_launcher.dart';

class CompactLinkPreview extends StatefulWidget {
  final String url;
  final Color textColor;
  final Color linkColor;

  const CompactLinkPreview({
    super.key,
    required this.url,
    required this.textColor,
    required this.linkColor,
  });

  @override
  State<CompactLinkPreview> createState() => _CompactLinkPreviewState();
}

class _CompactLinkPreviewState extends State<CompactLinkPreview> {
  String? _title;
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    try {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final document = html_parser.parse(response.body);
      final title = document.querySelector('meta[property="og:title"]')?.attributes['content']?.trim() ??
                   document.querySelector('title')?.text.trim();
      
      var imageUrl = document.querySelector('meta[property="og:image"]')?.attributes['content']?.trim();
      if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        if (imageUrl.startsWith('//')) {
          imageUrl = '${uri.scheme}:$imageUrl';
        } else if (imageUrl.startsWith('/')) {
          imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
        }
      }

      if (mounted) {
        setState(() {
          _title = title?.isNotEmpty == true ? title : uri.host;
          _imageUrl = imageUrl?.isNotEmpty == true ? imageUrl : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _title = Uri.parse(widget.url).host;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 60,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.textColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.textColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading preview...',
              style: TextStyle(
                color: widget.textColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => UrlLauncher(context, widget.url).launchUrl(),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.link,
                          size: 18,
                          color: widget.linkColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.link,
                      size: 18,
                      color: widget.linkColor,
                    ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _title ?? Uri.parse(widget.url).host,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}