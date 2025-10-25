import 'package:flutter/material.dart';

class ChatListGroup extends StatelessWidget {
  final List<Widget> children;

  const ChatListGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: children,
      ),
    );
  }
}
