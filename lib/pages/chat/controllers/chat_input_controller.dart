import 'dart:async';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatInputController {
  final Room room;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode;
  
  Timer? _typingCoolDown;
  Timer? _typingTimeout;
  Timer? _storeInputTimer;
  bool _currentlyTyping = false;
  
  ChatInputController(this.room, this.focusNode);
  
  void onChanged(String text) {
    _handleTypingIndicator();
    _storeDraft(text);
  }
  
  void _handleTypingIndicator() {
    _typingCoolDown?.cancel();
    _typingCoolDown = Timer(const Duration(seconds: 2), () {
      _typingCoolDown = null;
      _currentlyTyping = false;
      room.setTyping(false);
    });
    
    _typingTimeout ??= Timer(const Duration(seconds: 30), () {
      _typingTimeout = null;
      _currentlyTyping = false;
    });
    
    if (!_currentlyTyping) {
      _currentlyTyping = true;
      room.setTyping(true, timeout: 30000);
    }
  }
  
  void _storeDraft(String text) {
    _storeInputTimer?.cancel();
    _storeInputTimer = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_${room.id}', text);
    });
  }
  
  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('draft_${room.id}');
    if (draft != null && draft.isNotEmpty) {
      textController.text = draft;
    }
  }
  
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_${room.id}');
  }
  
  void dispose() {
    _typingCoolDown?.cancel();
    _typingTimeout?.cancel();
    _storeInputTimer?.cancel();
    textController.dispose();
  }
}
