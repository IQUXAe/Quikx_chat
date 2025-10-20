import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../../../l10n/l10n.dart';

class StatusDialog extends StatefulWidget {
  final String currentStatus;
  final PresenceType currentPresence;
  
  const StatusDialog({
    super.key,
    required this.currentStatus,
    required this.currentPresence,
  });
  
  @override
  State<StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<StatusDialog> {
  late TextEditingController _controller;
  late PresenceType _selectedPresence;
  
  static const List<String> _quickStatuses = [
    '🏠 Working from home',
    '🏢 At the office', 
    '🍕 At lunch',
    '☕ Coffee break',
    '🚗 Commuting',
    '🎯 Focused',
    '📱 Available',
    '😴 Do not disturb',
  ];
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentStatus);
    _selectedPresence = widget.currentPresence;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(L10n.of(context).setStatus),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Presence', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<PresenceType>(
              segments: const [
                ButtonSegment(value: PresenceType.online, label: Text('🟢 Online')),
                ButtonSegment(value: PresenceType.unavailable, label: Text('🟡 Away')),
                ButtonSegment(value: PresenceType.offline, label: Text('⚫ Offline')),
              ],
              selected: {_selectedPresence},
              onSelectionChanged: (selection) => setState(() => _selectedPresence = selection.first),
            ),
            const SizedBox(height: 16),
            Text('Status Message', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: L10n.of(context).statusExampleMessage,
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text('Quick Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 4,
                ),
                itemCount: _quickStatuses.length,
                itemBuilder: (context, index) => OutlinedButton(
                  onPressed: () {
                    _controller.text = _quickStatuses[index];
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(_quickStatuses[index], style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L10n.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'status': _controller.text.trim(),
            'presence': _selectedPresence,
          }),
          child: Text(L10n.of(context).ok),
        ),
      ],
    );
  }
}
