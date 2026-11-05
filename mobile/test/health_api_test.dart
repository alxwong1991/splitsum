import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/api/health_api.dart';

void main() {
  test(
    'requests readiness and validates both backend and database status',
    () async {
      final api = HealthApi(
        baseUrl: 'http://localhost:3000',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'http://localhost:3000/health/ready');
          return http.Response('{"status":"ok","database":"up"}', 200);
        }),
      );
      addTearDown(api.close);
      await api.check();
    },
  );

  for (final entry in [
    (503, '{"status":"error","database":"down"}', 'PostgreSQL is unavailable'),
    (500, '', 'HTTP 500'),
    (200, '<html>not JSON</html>', 'invalid readiness'),
    (200, '{}', 'unexpected readiness'),
    (200, 'null', 'unexpected readiness'),
    (200, '{"status":"ok","database":"down"}', 'unexpected readiness'),
  ]) {
    test('rejects response ${entry.$1} ${entry.$2}', () async {
      final api = HealthApi(
        baseUrl: 'http://localhost:3000',
        client: MockClient((_) async => http.Response(entry.$2, entry.$1)),
      );
      addTearDown(api.close);
      await expectLater(
        api.check(),
        throwsA(
          isA<ConnectionCheckException>().having(
            (error) => error.message,
            'message',
            contains(entry.$3),
          ),
        ),
      );
    });
  }

  for (final url in [
    '',
    'not a URL',
    'ftp://localhost',
    'http://user:password@localhost',
    'http://localhost/api',
    'http://localhost?token=secret',
  ]) {
    test('rejects invalid configuration before networking: $url', () async {
      final api = HealthApi(
        baseUrl: url,
        client: MockClient((_) async => throw StateError('Must not request')),
      );
      addTearDown(api.close);
      await expectLater(api.check(), throwsA(isA<ConnectionCheckException>()));
    });
  }

  test('reports network failures without leaking driver details', () async {
    final api = HealthApi(
      baseUrl: 'http://localhost:3000',
      client: MockClient(
        (_) async => throw http.ClientException('private error'),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.check(),
      throwsA(
        isA<ConnectionCheckException>().having(
          (error) => error.message,
          'message',
          startsWith('Cannot reach the backend.'),
        ),
      ),
    );
  });

  test('reports a request timeout', () async {
    final pending = Completer<http.Response>();
    final api = HealthApi(
      baseUrl: 'http://localhost:3000',
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) => pending.future),
    );
    addTearDown(api.close);
    await expectLater(
      api.check(),
      throwsA(
        isA<ConnectionCheckException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
    pending.complete(http.Response('{}', 200));
  });
}
