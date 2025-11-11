import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:quikxchat/config/env_config.dart';

class VoiceToTextClient {
  static final _random = Random();
  
  static List<String> _getServers() {
    return EnvConfig.v2tServerUrl.split(',').map((s) => s.trim()).toList();
  }
  
  static Future<String> convert(Uint8List audioBytes, String fileName) async {
    final servers = _getServers();
    
    // Shuffle servers for random selection
    final shuffledServers = List<String>.from(servers)..shuffle(_random);
    
    Exception? lastError;
    
    for (final serverUrl in shuffledServers) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        
        final signature = Hmac(sha256, utf8.encode(EnvConfig.v2tSecretKey))
            .convert(utf8.encode(timestamp.toString()))
            .toString();
        
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$serverUrl/v2t'),
        );
        
        request.headers['X-Signature'] = signature;
        request.headers['X-Timestamp'] = timestamp.toString();
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: fileName,
        ));
        
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        
        if (response.statusCode == 200) {
          final json = jsonDecode(responseData);
          return json['text'] as String;
        } else {
          final json = jsonDecode(responseData);
          throw Exception('${response.statusCode}: ${json['error'] ?? responseData}');
        }
      } catch (e) {
        lastError = e as Exception;
        continue;
      }
    }
    
    throw lastError ?? Exception('All servers failed');
  }
}
