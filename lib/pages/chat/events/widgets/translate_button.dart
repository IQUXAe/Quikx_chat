import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../../../../utils/message_translator.dart';
import '../message.dart';

class TranslateButton extends StatefulWidget {
  final Event event;
  final Color color;
  
  const TranslateButton({
    super.key,
    required this.event,
    required this.color,
  });
  
  @override
  State<TranslateButton> createState() => _TranslateButtonState();
}

class _TranslateButtonState extends State<TranslateButton> {
  bool _isTranslating = false;
  
  @override
  Widget build(BuildContext context) {
    final hasTranslation = messageTranslations.containsKey(widget.event.eventId);
    
    if (_isTranslating) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(widget.color),
          ),
        ),
      );
    }
    
    return IconButton(
      icon: Icon(
        hasTranslation ? Icons.translate : Icons.translate_outlined,
        size: 18,
      ),
      color: widget.color,
      onPressed: _toggleTranslation,
      tooltip: hasTranslation ? 'Show original' : 'Translate message',
      visualDensity: VisualDensity.compact,
    );
  }
  
  Future<void> _toggleTranslation() async {
    if (messageTranslations.containsKey(widget.event.eventId)) {
      setState(() {
        messageTranslations.remove(widget.event.eventId);
        notifyTranslationChanged();
      });
      return;
    }
    
    setState(() => _isTranslating = true);
    
    try {
      final translation = await MessageTranslator.translateMessage(
        widget.event.body,
        'auto',
      ).timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      
      if (translation != null && translation.isNotEmpty) {
        setState(() {
          messageTranslations[widget.event.eventId] = translation;
          notifyTranslationChanged();
        });
      }
    } catch (e) {
      Logs().w('Translation failed', e);
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }
}
