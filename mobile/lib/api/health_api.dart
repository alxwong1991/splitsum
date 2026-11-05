import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectionCheckException implements Exception {
  const ConnectionCheckException(this.message);

  final String message;
}

class HealthApi {
  HealthApi({
    required this.baseUrl,
    required this.client,
    this.timeout = const Duration(seconds: 8),
  });

  final String baseUrl;
  final http.Client client;
  final Duration timeout;

  Future<void> check() async {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.host.isEmpty ||
        !['http', 'https'].contains(base.scheme) ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const ConnectionCheckException(
        'Set API_BASE_URL to the backend origin, for example '
        'http://localhost:3000.',
      );
    }
    if (kReleaseMode && base.scheme != 'https') {
      throw const ConnectionCheckException(
        'Release builds require an HTTPS backend URL.',
      );
    }

    final http.Response response;
    try {
      response = await client
          .get(base.resolve('/health/ready'))
          .timeout(timeout);
    } on TimeoutException {
      throw const ConnectionCheckException(
        'Connection timed out. Check the backend and try again.',
      );
    } on http.ClientException {
      throw const ConnectionCheckException(
        'Cannot reach the backend. Check its address, network access, '
        'and that NestJS is running.',
      );
    }

    if (response.statusCode == 503) {
      throw const ConnectionCheckException(
        'Backend is reachable, but PostgreSQL is unavailable.',
      );
    }
    if (response.statusCode != 200) {
      throw ConnectionCheckException(
        'Backend returned HTTP ${response.statusCode}. '
        'Check the readiness endpoint.',
      );
    }

    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const ConnectionCheckException(
        'Backend returned an invalid readiness response.',
      );
    }
    if (body is! Map<String, dynamic> ||
        body['status'] != 'ok' ||
        body['database'] != 'up') {
      throw const ConnectionCheckException(
        'Backend returned an unexpected readiness response.',
      );
    }
  }

  void close() => client.close();
}
