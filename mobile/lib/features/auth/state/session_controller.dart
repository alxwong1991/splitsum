import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_store.dart';
import '../data/auth_api.dart';
import '../models/account.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.store});
  final AuthApi api;
  final TokenStore store;
  Account? account;
  String? error;
  bool restoring = true;
  bool busy = false;
  bool restoreFailed = false;
  StoredSession? _session;
  Timer? _timer;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restore() async {
    restoring = true;
    restoreFailed = false;
    error = null;
    _notify();
    try {
      _session = await store.read();
      if (_session != null) {
        if (!_session!.expiresAt.isAfter(DateTime.now())) {
          await _clear('Your session has ended. Please sign in again.');
        } else {
          account = await api.me(_session!.token);
          _scheduleExpiry();
        }
      }
    } on ApiException catch (failure) {
      if (failure.status == 401) {
        await _clear(failure.message);
      } else {
        error = failure.message;
        restoreFailed = true;
      }
    } on TokenStorageException {
      error =
          'Cannot read secure session storage. Retry or clear this session.';
      restoreFailed = true;
    } finally {
      restoring = false;
      _notify();
    }
  }

  Future<void> authenticate({
    required bool register,
    required String email,
    required String password,
  }) async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      final result = await api.authenticate(
        register: register,
        email: email,
        password: password,
      );
      final session = StoredSession(
        result.token,
        DateTime.now().add(Duration(seconds: result.expiresIn)),
      );
      await store.write(session);
      _session = session;
      account = result.account;
      _scheduleExpiry();
    } on ApiException catch (failure) {
      error = failure.message;
    } on TokenStorageException {
      error =
          'Sign-in succeeded, but the token could not be stored securely. '
          'No session was opened. Retry signing in.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> reload() => _accountOperation(() => api.me(_session!.token));
  Future<void> updateName(String name) =>
      _accountOperation(() => api.updateName(_session!.token, name));

  Future<T> withSession<T>(Future<T> Function(String token) operation) async {
    final session = _session;
    if (session == null || !session.expiresAt.isAfter(DateTime.now())) {
      if (session != null) {
        await _clear('Your session has ended. Please sign in again.');
      }
      throw const ApiException(
        'Your session has ended. Please sign in again.',
        status: 401,
      );
    }
    try {
      return await operation(session.token);
    } on ApiException catch (failure) {
      if (failure.status == 401 && identical(_session, session)) {
        await _clear(failure.message);
      }
      rethrow;
    }
  }

  Future<void> _accountOperation(Future<Account> Function() operation) async {
    if (busy || _session == null) return;
    busy = true;
    error = null;
    _notify();
    try {
      final updated = await operation();
      if (_session != null) account = updated;
    } on ApiException catch (failure) {
      if (failure.status == 401) {
        await _clear(failure.message);
      } else {
        error = failure.message;
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    busy = true;
    await _clear(null);
    busy = false;
    _notify();
  }

  Future<void> _clear(String? message) async {
    _timer?.cancel();
    _session = null;
    account = null;
    restoreFailed = false;
    error = message;
    try {
      await store.delete();
    } on TokenStorageException {
      restoreFailed = true;
      error = 'Could not remove the secure token. Retry clearing the session.';
    }
    _notify();
  }

  void _scheduleExpiry() {
    _timer?.cancel();
    if (_disposed) return;
    final duration = _session!.expiresAt.difference(DateTime.now());
    _timer = Timer(duration.isNegative ? Duration.zero : duration, () {
      unawaited(_clear('Your session has ended. Please sign in again.'));
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
