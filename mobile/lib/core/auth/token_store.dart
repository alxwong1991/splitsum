import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  const StoredSession(this.token, this.expiresAt);
  final String token;
  final DateTime expiresAt;
}

class TokenStorageException implements Exception {
  const TokenStorageException();
}

abstract class TokenStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> delete();
}

// Browser previews do not persist bearer tokens in browser storage.
class EphemeralTokenStore implements TokenStore {
  StoredSession? _session;
  @override
  Future<StoredSession?> read() async => _session;
  @override
  Future<void> write(StoredSession session) async => _session = session;
  @override
  Future<void> delete() async => _session = null;
}

class SecureTokenStore implements TokenStore {
  final _storage = const FlutterSecureStorage();
  static const _key = 'splitsum.session';

  @override
  Future<StoredSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> ||
          value['token'] is! String ||
          (value['token'] as String).isEmpty ||
          value['expiresAt'] is! String) {
        throw const FormatException('Invalid stored session.');
      }
      return StoredSession(
        value['token'] as String,
        DateTime.parse(value['expiresAt'] as String),
      );
    } on PlatformException {
      throw const TokenStorageException();
    } on FormatException {
      throw const TokenStorageException();
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'token': session.token,
          'expiresAt': session.expiresAt.toIso8601String(),
        }),
      );
    } on PlatformException {
      throw const TokenStorageException();
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(key: _key);
    } on PlatformException {
      throw const TokenStorageException();
    }
  }
}
