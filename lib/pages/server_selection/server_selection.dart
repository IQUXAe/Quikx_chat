import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'server_selection_view.dart';

class ServerSelection extends StatefulWidget {
  const ServerSelection({super.key});

  @override
  ServerSelectionController createState() => ServerSelectionController();
}

class ServerSelectionController extends State<ServerSelection> {
  String? selectedServer = 'matrix';
  bool isLoading = false;

  final List<ServerOption> servers = [
    const ServerOption(
      id: 'matrix',
      name: 'matrix.org',
      description: '',
      registrationUrl: 'https://app.element.io/#/register',
    ),
    const ServerOption(
      id: 'envs',
      name: 'envs.net',
      description: '',
      registrationUrl: 'https://element.envs.net/#/register',
    ),
    const ServerOption(
      id: 'g24',
      name: 'g24.at',
      description: '',
      registrationUrl: 'https://element.g24.at/#/register',
    ),
    const ServerOption(
      id: 'imagisphe',
      name: 'imagisphe.re',
      description: '',
      registrationUrl: 'https://element.imagisphe.re/#/register',
    ),
    const ServerOption(
      id: 'socialnetwork24',
      name: 'socialnetwork24.com',
      description: '',
      registrationUrl: 'https://chat.socialnetwork24.com/#/register',
    ),
    const ServerOption(
      id: 'gnulinux',
      name: 'gnulinux.club',
      description: '',
      registrationUrl: 'https://element.gnulinux.club/#/register',
    ),
    const ServerOption(
      id: 'jonasled',
      name: 'jonasled.de',
      description: '',
      registrationUrl: 'https://chat.jonasled.de/#/register',
    ),
  ];

  void selectServer(String serverId) {
    setState(() {
      selectedServer = serverId;
    });
  }

  Future<void> continueWithSelectedServer() async {
    if (selectedServer == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final server = servers.firstWhere((s) => s.id == selectedServer);
      await launchUrlString(server.registrationUrl);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> continueWithUniversal() async {
    setState(() {
      isLoading = true;
    });

    try {
      await launchUrlString('https://app.element.io/#/register');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ServerSelectionView(this);
}

class ServerOption {
  final String id;
  final String name;
  final String description;
  final String registrationUrl;

  const ServerOption({
    required this.id,
    required this.name,
    required this.description,
    required this.registrationUrl,
  });
}