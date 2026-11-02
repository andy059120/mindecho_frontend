import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.client, String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://mindechoserver.com:8443/api',
          );
  final http.Client client;
  final String baseUrl;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path')
        .replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    try {
      final response = await _send(request)
          .timeout(const Duration(seconds: 30));
      Map<String, dynamic>? payload;
      if (response.bodyBytes.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) payload = decoded;
        } on FormatException {
          /* 非 JSON 錯誤頁交由 HTTP 狀態處理。 */
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final fallback = switch (response.statusCode) {
          401 => '登入已失效，請重新登入',
          429 => '免費額度已用完，請稍後再試',
          _ => '伺服器錯誤（${response.statusCode}），請稍後再試',
        };
        throw ApiException(
          payload?['message'] is String
              ? payload!['message'] as String
              : fallback,
          status: response.statusCode,
        );
      }
      if (response.bodyBytes.isEmpty) return {};
      if (payload == null) throw const ApiException('伺服器回應格式異常');
      return payload;
    } on TimeoutException {
      throw const ApiException('連線逾時，請稍後再試');
    } on http.ClientException {
      throw const ApiException('無法連線至伺服器，請檢查網路與伺服器憑證');
    }
  }

  Future<http.Response> _send(http.Request request) async =>
      http.Response.fromStream(await client.send(request));

  void close() => client.close();
}
