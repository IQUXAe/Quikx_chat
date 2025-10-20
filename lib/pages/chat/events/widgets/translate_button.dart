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
    
    return IconButton(
      icon: Icon(
        hasTranslation ? Icons.translate : Icons.translate_outlined,
        size: 16,
      ),
      color: widget.color,
      onPressed: _isTranslating ? null : _toggleTranslation,
      tooltip: hasTranslation ? 'Show original' : 'Translate',
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
      );
      
      if (translation != null && mounted) {
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
