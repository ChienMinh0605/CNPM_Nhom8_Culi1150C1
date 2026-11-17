import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Gọi REST API của backend. Token đăng nhập sẽ được gắn vào đây ở Sprint 1.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _http;
  final String _baseUrl;

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _http.get(Uri.parse('$_baseUrl$path'));
    return _decode(response);
  }

  /// POST, PUT, DELETE. Trả về map rỗng khi máy chủ không gửi nội dung (204).
  Future<Map<String, dynamic>> send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _decode(await http.Response.fromStream(await _http.send(request)));
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = body['error'];
      final message = error is Map<String, dynamic>
          ? (error['message'] as String? ?? 'Lỗi không xác định')
          : 'Lỗi không xác định';
      throw ApiException(response.statusCode, message);
    }
    return body;
  }
}
