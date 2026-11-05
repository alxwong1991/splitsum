import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/api_exception.dart';

void main() {
  test('sends shared headers and JSON without assuming a feature', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3000/groups');
        expect(request.method, 'POST');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Authorization'], 'Bearer synthetic-token');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {'name': 'Dinner', 'position': 1});
        return http.Response('{"id":"group-id"}', 201);
      }),
    );
    addTearDown(api.close);
    expect(
      await api.request(
        'POST',
        '/groups',
        token: 'synthetic-token',
        body: {'name': 'Dinner', 'position': 1},
      ),
      {'id': 'group-id'},
    );
  });

  test('public requests omit bearer headers and allow 204', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response('', 204);
      }),
    );
    addTearDown(api.close);
    expect(await api.request('DELETE', '/example'), isNull);
  });

  for (final status in [302, 400, 401, 403, 409, 429, 500]) {
    test('reports HTTP $status with its status code', () async {
      final api = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient((_) async => http.Response('{}', status)),
      );
      addTearDown(api.close);
      await expectLater(
        api.request('GET', '/groups'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', status)),
      );
    });
  }

  test('rejects malformed JSON', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) async => http.Response('not JSON', 200)),
    );
    addTearDown(api.close);
    await expectLater(
      api.request('GET', '/groups'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('invalid response'),
        ),
      ),
    );
  });

  test('rejects external endpoints before sending a bearer token', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) async {
        fail('Invalid endpoints must not make requests.');
      }),
    );
    addTearDown(api.close);
    for (final path in [
      'https://example.invalid/users',
      '//example.invalid',
      'groups',
    ]) {
      await expectLater(
        api.request('GET', path, token: 'synthetic-token'),
        throwsA(isA<ApiException>()),
      );
    }
  });

  testWidgets('timeouts warn that writes may have completed', (tester) async {
    final pending = Completer<http.Response>();
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) => pending.future),
    );
    addTearDown(api.close);
    final assertion = expectLater(
      api.request('POST', '/groups', body: {'name': 'Dinner'}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Changes may have completed'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 12));
    await assertion;
    pending.complete(http.Response('{}', 201));
    await tester.pump();
  });
}
