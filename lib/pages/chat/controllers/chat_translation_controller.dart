import 'dart:async';
import 'package:matrix/matrix.dart';
import '../../../utils/message_translator.dart';
import '../events/message.dart';

class ChatTranslationController {
  bool _autoTranslateEnabled = false;
  bool get autoTranslateEnabled => _autoTranslateEnabled;
  
  final void Function() onUpdate;
  
  ChatTranslationController(this.onUpdate);
  
  void toggle() {
    _autoTranslateEnabled = !_autoTranslateEnabled;
    if (!_autoTranslateEnabled) {
      clearTranslations();
    }
    onUpdate();
  }
  
  Future<void> translateVisibleMessages(List<Event> events) async {
    if (!_autoTranslateEnabled || !await MessageTranslator.isEnabled) return;
    
    final textEvents = events.where((e) => 
      e.type == EventTypes.Message && 
      e.messageType == MessageTypes.Text &&
      e.body.trim().isNotEmpty &&
      !messageTranslations.containsKey(e.eventId),
    ).toList();
    
    if (textEvents.isEmpty) return;
    
    for (final event in textEvents.take(3)) {
      try {
        final translation = await MessageTranslator.translateMessage(event.body, 'auto');
        if (translation != null) {
          messageTranslations[event.eventId] = translation;
        }
      } catch (e) {
        Logs().v('Translation failed: $e');
      }
    }
    
    _cleanup();
    onUpdate();
  }
  
  void _cleanup() {
    if (messageTranslations.length > 100) {
      final keys = messageTranslations.keys.toList();
      for (var i = 0; i < keys.length - 100; i++) {
        messageTranslations.remove(keys[i]);
      }
    }
  }
  
  void clearTranslations() {
    messageTranslations.clear();
  }
  
  void dispose() {
    clearTranslations();
  }
}
