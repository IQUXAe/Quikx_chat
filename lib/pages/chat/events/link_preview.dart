import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:simplemessenger/utils/url_launcher.dart';

// Simple cache for link previews
final Map<String, LinkPreviewData?> _previewCache = <String, LinkPreviewData?>{};
final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};
const Duration _cacheExpiry = Duration(hours: 1);
const int _maxCacheSize = 100;

// Clean up old cache entries
void _cleanupCache() {
  final now = DateTime.now();
  final expiredKeys = _cacheTimestamps.entries
      .where((entry) => now.difference(entry.value) > _cacheExpiry)
      .map((entry) => entry.key)
      .toList();
  
  for (final key in expiredKeys) {
    _previewCache.remove(key);
    _cacheTimestamps.remove(key);
  }
  
  // If cache is still too large, remove oldest entries
  if (_previewCache.length > _maxCacheSize) {
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final entriesToRemove = sortedEntries.take(_previewCache.length - _maxCacheSize);
    for (final entry in entriesToRemove) {
      _previewCache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }
}

class LinkPreview extends StatefulWidget {
  final String url;
  final Color textColor;
  final Color linkColor;

  const LinkPreview({
    super.key,
    required this.url,
    required this.textColor,
    required this.linkColor,
  });

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  LinkPreviewData? _previewData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _cleanupCache();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    if (!mounted) return;
    
    // Check cache first
    final cacheKey = widget.url;
    final cachedTimestamp = _cacheTimestamps[cacheKey];
    if (cachedTimestamp != null && 
        DateTime.now().difference(cachedTimestamp) < _cacheExpiry &&
        _previewCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _previewData = _previewCache[cacheKey];
          _isLoading = false;
        });
      }
      return;
    }
    
    try {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; LinkPreview/1.0)',
        },
      ).timeout(const Duration(seconds: 8));
      
      if (!mounted) return;
      
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      final document = html_parser.parse(response.body);
      
      String? title = document.querySelector('meta[property="og:title"]')?.attributes['content']?.trim() ??
                     document.querySelector('meta[name="twitter:title"]')?.attributes['content']?.trim() ??
                     document.querySelector('title')?.text?.trim();
      
      String? description = document.querySelector('meta[property="og:description"]')?.attributes['content']?.trim() ??
                           document.querySelector('meta[name="twitter:description"]')?.attributes['content']?.trim() ??
                           document.querySelector('meta[name="description"]')?.attributes['content']?.trim();
      
      String? imageUrl = document.querySelector('meta[property="og:image"]')?.attributes['content']?.trim() ??
                        document.querySelector('meta[name="twitter:image"]')?.attributes['content']?.trim();
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (!imageUrl.startsWith('http')) {
          if (imageUrl.startsWith('//')) {
            imageUrl = '${uri.scheme}:$imageUrl';
          } else if (imageUrl.startsWith('/')) {
            imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
          } else {
            imageUrl = '${uri.scheme}://${uri.host}/${imageUrl}';
          }
        }
      }

      if (mounted) {
        final previewData = LinkPreviewData(
          title: title?.isNotEmpty == true ? title : null,
          description: description?.isNotEmpty == true ? description : null,
          imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
          url: widget.url,
        );
        
        // Cache the result
        _previewCache[cacheKey] = previewData;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        setState(() {
          _previewData = previewData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || _isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasError || _previewData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 400,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: widget.textColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => UrlLauncher(context, widget.url).launchUrl(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_previewData!.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      child: Image.network(
                        _previewData!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: widget.textColor.withOpacity(0.1),
                          child: Icon(Icons.image, color: widget.textColor.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_previewData!.title != null)
                  Text(
                    _previewData!.title!,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_previewData!.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _previewData!.description!,
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  Uri.parse(widget.url).host,
                  style: TextStyle(
                    color: widget.linkColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LinkPreviewData {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  LinkPreviewData({
    this.title,
    this.description,
    this.imageUrl,
    required this.url,
  });
}