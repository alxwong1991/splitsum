import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/features/auth/state/session_controller.dart';

const accountJson =
    '{"id":"fixture-id","email":"alex@example.invalid",'
    '"displayName":null,"createdAt":"2026-11-05T00:00:00Z"}';
const authJson =
    '{"accessToken":"synthetic-token","tokenType":"Bearer",'
    '"expiresIn":1800,"user":$accountJson}';

class MemoryTokenStore implements TokenStore {
  StoredSession? value;
  bool failWrite = false;
  bool failRead = false;
  bool failDelete = false;
  @override
  Future<StoredSession?> read() async {
    if (failRead) throw const TokenStorageException();
    return value;
  }

  @override
  Future<void> write(StoredSession session) async {
    if (failWrite) throw const TokenStorageException();
    value = session;
  }

  @override
  Future<void> delete() async {
    if (failDelete) throw const TokenStorageException();
    value = null;
  }
}

SessionController testSession({
  MemoryTokenStore? store,
  Future<http.Response> Function(http.Request)? handler,
}) => SessionController(
  store: store ?? MemoryTokenStore(),
  api: AuthApi(
    client: ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient(
        handler ?? (_) async => http.Response(accountJson, 200),
      ),
    ),
  ),
);
