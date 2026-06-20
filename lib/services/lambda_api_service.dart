import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LambdaApiService {
  LambdaApiService({http.Client? httpClient})
      : _client = httpClient ?? http.Client() {
    _baseUrl = dotenv.env['AWS_API_BASE_URL'] ?? '';
    if (_baseUrl.isNotEmpty) {
      debugPrint('[LambdaApiService] API Gateway configured at $_baseUrl');
      _isConfigured = true;
    } else {
      debugPrint('[LambdaApiService] AWS_API_BASE_URL not found in .env. Running in offline Mock Data mode.');
    }
  }

  final http.Client _client;
  late final String _baseUrl;
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  String? _jwtToken;

  void setJwtToken(String? token) {
    _jwtToken = token;
  }

  Map<String, String> _headers() {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    if (!_isConfigured) {
      throw StateError('AWS API Gateway not configured. Running offline.');
    }
    final http.Response response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
    );
    return _parseResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    if (!_isConfigured) {
      throw StateError('AWS API Gateway not configured. Running offline.');
    }
    final http.Response response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    if (!_isConfigured) {
      throw StateError('AWS API Gateway not configured. Running offline.');
    }
    final http.Response response = await _client.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<dynamic> delete(String path) async {
    if (!_isConfigured) {
      throw StateError('AWS API Gateway not configured. Running offline.');
    }
    final http.Response response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
    );
    return _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    final int code = response.statusCode;
    if (code >= 200 && code < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('API call failed with status: $code. Body: ${response.body}');
    }
  }
}
