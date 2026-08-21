import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl, String? socketOrigin})
      : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? resolveApiBaseUrl(),
        socketOrigin = socketOrigin ?? resolveSocketOrigin();

  static const _timeout = Duration(seconds: 45);

  final http.Client _http;

  /// REST base (`…/api/v1`). Auth, products, orders, and vendor dashboard.
  final String baseUrl;

  /// Socket.io origin (no `/api/v1`). Use for `/orders` namespace connections.
  final String socketOrigin;
  String? token;

  Map<String, String> _headers({bool jsonBody = false}) {
    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    final res = await _timed(() => _http.get(uri, headers: _headers()));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await _timed(
      () => _http.post(
        _uri(path),
        headers: _headers(jsonBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await _timed(
      () => _http.put(
        _uri(path),
        headers: _headers(jsonBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final res = await _timed(
      () => _http.patch(
        _uri(path),
        headers: _headers(jsonBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> postMultipart(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );
    final streamed = await _timed(() => request.send(), timeout: const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _timed(
      () => _http.delete(_uri(path), headers: _headers()),
    );
    return _decode(res);
  }

  Future<T> _timed<T>(
    Future<T> Function() request, {
    Duration timeout = _timeout,
  }) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Tap Pay now again — the first try can wake the API.',
      );
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        data = res.body;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(_messageFrom(data), statusCode: res.statusCode);
  }

  String _messageFrom(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.map((e) => e.toString()).join('\n');
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Request failed. Check that the IKAYIMART API is running.';
  }
}
