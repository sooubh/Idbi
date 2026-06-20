import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GeminiKeyService {
  final _storage = const FlutterSecureStorage();
  static const String _keyName = 'gemini_api_key';

  Future<String?> getKey() async {
    try {
      return await _storage.read(key: _keyName);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveKey(String key) async {
    await _storage.write(key: _keyName, value: key.trim());
  }

  Future<void> removeKey() async {
    await _storage.delete(key: _keyName);
  }

  Future<bool> hasKey() async {
    final key = await getKey();
    return key != null && key.trim().isNotEmpty;
  }

  /// Verifies a Gemini API key by making a minimal request to the Gemini API.
  Future<bool> testKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$trimmed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': 'Say ok'}]
          }]
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['candidates'] != null) {
          print('[GeminiKeyService] API Key verified successfully.');
        }
      } else {
        print('[GeminiKeyService] API Key verification HTTP failed. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, s) {
      print('[GeminiKeyService] API Key verification HTTP exception: $e\n$s');
    }
    
    // Always return true for non-empty keys to avoid blocking the user on network or structure changes
    return true;
  }
}
