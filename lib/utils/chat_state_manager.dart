import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';

/// Состояние чата для управления UI-состоянием чата
class ChatUIState extends ChangeNotifier {
  // Состояние выбора сообщений
  final Set<Event> _selectedEvents = <Event>{};
  Set<Event> get selectedEvents => _selectedEvents;
  
  // Состояние ответа
  Event? _replyEvent;
  Event? get replyEvent => _replyEvent;
  set replyEvent(Event? event) {
    _replyEvent = event;
    notifyListeners();
  }
  
  // Состояние редактирования
  Event? _editEvent;
  Event? get editEvent => _editEvent;
  set editEvent(Event? event) {
    _editEvent = event;
    notifyListeners();
  }
  
  // Режим выбора
  bool get selectMode => _selectedEvents.isNotEmpty;
  
  // Текст, который в данный момент редактируется
  String _pendingText = '';
  String get pendingText => _pendingText;
  set pendingText(String text) {
    _pendingText = text;
    notifyListeners();
  }
  
  // Состояние эмодзи пикера
  bool _showEmojiPicker = false;
  bool get showEmojiPicker => _showEmojiPicker;
  set showEmojiPicker(bool show) {
    _showEmojiPicker = show;
    notifyListeners();
  }
  
  // Состояние прокрутки
  bool _scrolledUp = false;
  bool get showScrollDownButton => _scrolledUp;
  set scrolledUp(bool up) {
    _scrolledUp = up;
    notifyListeners();
  }
  
  // Методы управления выбором сообщений
  void toggleEventSelection(Event event) {
    if (_selectedEvents.contains(event)) {
      _selectedEvents.remove(event);
    } else {
      _selectedEvents.add(event);
    }
    notifyListeners();
  }
  
  void clearEventSelection() {
    _selectedEvents.clear();
    notifyListeners();
  }
  
  void selectAllEvents(Iterable<Event> events) {
    _selectedEvents.addAll(events);
    notifyListeners();
  }
  
  // Метод сброса состояния
  void reset() {
    _selectedEvents.clear();
    _replyEvent = null;
    _editEvent = null;
    _pendingText = '';
    _showEmojiPicker = false;
    _scrolledUp = false;
    notifyListeners();
  }
}

/// Менеджер команд чата для обработки команд
class ChatCommandManager {
  /// Проверить, является ли сообщение командой
  static bool isCommand(String text) {
    return text.startsWith('/') && _extractCommand(text).isNotEmpty;
  }
  
  /// Извлечь команду из текста
  static String extractCommand(String text) {
    return isCommand(text) ? _extractCommand(text) : '';
  }
  
  static String _extractCommand(String text) {
    final match = RegExp(r'^\/(\w+)').firstMatch(text);
    return match?.group(1) ?? '';
  }
  
  /// Проверить, поддерживает ли команда аргументы
  static bool supportsArguments(String command) {
    return const ['me', 'spoiler', 'plain'].contains(command.toLowerCase());
  }
}

/// Утилиты для управления сообщениями
class ChatMessageUtils {
  /// Проверить, может ли сообщение быть отредактировано
  static bool canEdit(Event event, Client client) {
    return event.senderId == client.userID && 
           event.type == EventTypes.Message;
  }
  
  /// Проверить, может ли сообщение быть удалено
  static bool canDelete(Event event, Room room, Client client) {
    // Проверяем права пользователя 
    final userPower = room.getPowerLevelByUserId(client.userID!);
    return event.senderId == client.userID || 
           userPower >= 50; // Moderator or higher
  }
  
  /// Проверить, можно ли цитировать сообщение
  static bool canQuote(Event event) {
    return event.type == EventTypes.Message &&
           (event.content['msgtype'] == 'm.text' || 
            event.content['msgtype'] == 'm.emote' || 
            event.content['msgtype'] == 'm.notice');
  }
}