import 'package:quikxchat/utils/message_translator.dart';

class OptimizedMessageTranslator {
  static Future<String?> translateMessage(String text, String targetLang) async {
    return await MessageTranslator.translateMessage(text, targetLang);
  }
  
  static Future<void> clearCache() async {
    await MessageTranslator.clearCache();
  }
}