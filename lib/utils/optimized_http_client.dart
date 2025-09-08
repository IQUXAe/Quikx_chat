import 'dart:convert';
import 'package:http/http.dart' as http;

class OptimizedHttpClient {
  static final OptimizedHttpClient _instance = OptimizedHttpClient._internal();
  factory OptimizedHttpClient() => _instance;
  OptimizedHttpClient._internal();

  late final http.Client _client;
  
  void initialize() {
    _client = http.Client();
  }

  Future<Map<String, dynamic>?> getJson(String url, {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}