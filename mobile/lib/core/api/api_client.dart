import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({required this.client, required this.baseUrl});
  final http.Client client;
  final String baseUrl;

  Future<Object?> request(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.host.isEmpty ||
        !['http', 'https'].contains(base.scheme) ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const ApiException(
        'Configure API_BASE_URL with the backend origin before signing in.',
      );
    }
    if (kReleaseMode && base.scheme != 'https') {
      throw const ApiException('Release builds require an HTTPS backend.');
    }
    final endpoint = Uri.tryParse(path);
    if (endpoint == null ||
        !path.startsWith('/') ||
        endpoint.hasAuthority ||
        endpoint.hasScheme ||
        endpoint.hasFragment) {
      throw const ApiException('API endpoints must be backend-relative paths.');
    }
    final request = http.Request(method, base.resolveUri(endpoint))
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw ApiException(
        'Request timed out. Changes may have completed. '
        'Check the result before retrying; for registration, try signing in.',
        outcomeUnknown: method != 'GET',
      );
    } on http.ClientException {
      throw ApiException(
        'Cannot reach the backend. Check the network and server address.',
        outcomeUnknown: method != 'GET',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (response.statusCode) {
        401 => 'Your session has ended. Please sign in again.',
        429 => 'Too many attempts. Wait a minute before trying again.',
        400 => 'Check your input. The server rejected these details.',
        _ => 'Server error (${response.statusCode}). Please try again.',
      };
      throw ApiException(
        message,
        status: response.statusCode,
        outcomeUnknown:
            method != 'GET' &&
            (response.statusCode >= 500 || response.statusCode < 400),
      );
    }
    if (response.statusCode == 204) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The backend returned an invalid response.',
        outcomeUnknown: method != 'GET',
      );
    }
  }

  void close() => client.close();
}
