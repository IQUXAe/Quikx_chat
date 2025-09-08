import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class CachedProfileWidget extends StatefulWidget {
  final Client client;
  final Widget Function(BuildContext context, Profile? profile, bool isLoading) builder;

  const CachedProfileWidget({
    super.key,
    required this.client,
    required this.builder,
  });

  @override
  State<CachedProfileWidget> createState() => _CachedProfileWidgetState();
}

class _CachedProfileWidgetState extends State<CachedProfileWidget> {
  Profile? _cachedProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_isLoading || _cachedProfile != null) return;
    if (!widget.client.isLogged()) return;

    setState(() => _isLoading = true);

    try {
      final profile = await widget.client.fetchOwnProfile();
      if (mounted) {
        setState(() {
          _cachedProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _cachedProfile, _isLoading);
  }
}