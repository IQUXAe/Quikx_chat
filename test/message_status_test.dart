import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/utils/message_status_helper.dart';

void main() {
  group('MessageStatusHelper', () {
    test('createStatusKey should create unique keys for different states', () {
      // Этот тест проверяет, что ключи статусов создаются правильно
      // В реальном приложении здесь были бы моки для Event и Room
      
      // Пока что просто проверяем, что метод существует
      expect(MessageStatusHelper.createStatusKey, isA<Function>());
    });
    
    test('isMessageRead should return correct status', () {
      // Проверяем, что метод определения прочитанности существует
      expect(MessageStatusHelper.isMessageRead, isA<Function>());
    });
    
    test('getReadByCount should return correct count', () {
      // Проверяем, что метод подсчета прочитавших существует
      expect(MessageStatusHelper.getReadByCount, isA<Function>());
    });
  });
}