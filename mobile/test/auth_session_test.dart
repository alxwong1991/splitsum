import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/api_exception.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/features/auth/data/auth_api.dart';
import 'package:mobile/main.dart';

import 'auth_test_helpers.dart';

void main() {
  test('API normalizes email, preserves password, and sends bearer on private requests', () async {
    final api = AuthApi(
      client: ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient((req) async {
          if (req.url.path == '/auth/register') {
            expect(jsonDecode(req.body), {
              'email': 'alex@example.invalid',
              'password': ' password with spaces ',
            });
            return http.Response(authJson, 201);
          }
          expect(req.headers['Authorization'], 'Bearer synthetic-token');
          if (req.method == 'PATCH') {
            expect(jsonDecode(req.body), {'displayName': 'Alex'});
          }
          return http.Response(accountJson, 200);
        }),
      ),
    );
    addTearDown(api.close);
    final result = await api.authenticate(
      register: true,
      email: ' Alex@Example.Invalid ',
      password: ' password with spaces ',
    );
    await api.me(result.token);
    await api.updateName(result.token, ' Alex ');
  });

  for (final entry in [
    (401, 'Invalid email'),
    (409, 'Unable to register'),
    (429, 'Too many'),
    (500, 'Server error'),
    (200, 'invalid'),
  ]) {
    test('API explicitly reports ${entry.$1}', () async {
      final api = AuthApi(
        client: ApiClient(
          baseUrl: 'http://localhost:3000',
          client: MockClient((_) async => http.Response('{}', entry.$1)),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        api.authenticate(
          register: false,
          email: 'alex@example.invalid',
          password: 'synthetic-password',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains(entry.$2),
          ),
        ),
      );
    });
  }

  test('API reports network/configuration errors', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('private error'),
    );
    final api = AuthApi(
      client: ApiClient(baseUrl: 'http://localhost:3000', client: client),
    );
    addTearDown(api.close);
    await expectLater(
      api.me('token'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          startsWith('Cannot reach'),
        ),
      ),
    );
    final unconfigured = AuthApi(
      client: ApiClient(baseUrl: '', client: client),
    );
    await expectLater(
      unconfigured.me('token'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          startsWith('Configure API_BASE_URL'),
        ),
      ),
    );
  });

  test(
    'stores only session, restores from server, updates name, signs out',
    () async {
      final store = MemoryTokenStore();
      var changed = false;
      final session = testSession(
        store: store,
        handler: (req) async {
          if (req.url.path.startsWith('/auth/')) {
            return http.Response(authJson, 200);
          }
          if (req.method == 'PATCH') changed = true;
          return http.Response(
            changed
                ? accountJson.replaceFirst(
                    '"displayName":null',
                    '"displayName":"Alex"',
                  )
                : accountJson,
            200,
          );
        },
      );
      addTearDown(() {
        session.dispose();
        session.api.close();
      });
      await session.restore();
      await session.authenticate(
        register: false,
        email: 'alex@example.invalid',
        password: 'synthetic-password',
      );
      expect(store.value?.token, 'synthetic-token');
      expect(session.account?.email, 'alex@example.invalid');
      await session.updateName('Alex');
      expect(session.account?.displayName, 'Alex');

      final restored = testSession(store: store);
      addTearDown(() {
        restored.dispose();
        restored.api.close();
      });
      await restored.restore();
      expect(restored.account?.id, 'fixture-id');
      await restored.signOut();
      expect(restored.account, isNull);
      expect(store.value, isNull);
    },
  );

  test('failed storage write never opens a signed-in session', () async {
    final store = MemoryTokenStore()..failWrite = true;
    final session = testSession(
      store: store,
      handler: (_) async => http.Response(authJson, 200),
    );
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await session.restore();
    await session.authenticate(
      register: false,
      email: 'alex@example.invalid',
      password: 'synthetic-password',
    );
    expect(session.account, isNull);
    expect(session.error, contains('could not be stored securely'));
  });

  test(
    'server 401 clears token; transient errors keep restoration retryable',
    () async {
      final store = MemoryTokenStore()
        ..value = StoredSession(
          'token',
          DateTime.now().add(const Duration(minutes: 10)),
        );
      var status = 500;
      final session = testSession(
        store: store,
        handler: (_) async => http.Response('{}', status),
      );
      addTearDown(() {
        session.dispose();
        session.api.close();
      });
      await session.restore();
      expect(session.restoreFailed, isTrue);
      expect(store.value, isNotNull);
      status = 401;
      await session.restore();
      expect(session.restoreFailed, isFalse);
      expect(store.value, isNull);
      expect(session.error, contains('session has ended'));
    },
  );

  test('expired stored session is not sent over network', () async {
    final store = MemoryTokenStore()
      ..value = StoredSession(
        'token',
        DateTime.now().subtract(const Duration(seconds: 1)),
      );
    final session = testSession(
      store: store,
      handler: (_) async => throw StateError('Must not request'),
    );
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await session.restore();
    expect(store.value, isNull);
    expect(session.account, isNull);
  });

  test(
    'secure storage read/delete errors are explicit and retryable',
    () async {
      final store = MemoryTokenStore()..failRead = true;
      final session = testSession(store: store);
      addTearDown(() {
        session.dispose();
        session.api.close();
      });
      await session.restore();
      expect(session.restoreFailed, isTrue);
      store.failDelete = true;
      await session.signOut();
      expect(session.restoreFailed, isTrue);
      expect(session.error, contains('Could not remove'));
      store.failDelete = false;
      await session.signOut();
      expect(session.restoreFailed, isFalse);
    },
  );

  testWidgets('registration -> private name -> explicit demo -> sign out', (
    tester,
  ) async {
    final session = testSession(
      handler: (req) async {
        if (req.url.path.startsWith('/auth/')) {
          return http.Response(authJson, 201);
        }
        return http.Response(
          accountJson.replaceFirst(
            '"displayName":null',
            '"displayName":"Alex"',
          ),
          200,
        );
      },
    );
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    await tap(tester, 'New here? Create account');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@example.invalid',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'synthetic passphrase!',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'synthetic passphrase!',
    );
    await tap(tester, 'Create account');
    expect(find.text('Your account'), findsOneWidget);
    expect(find.text('Friday Dinner'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tap(tester, 'Save display name');
    expect(find.text('Hello, Alex.'), findsOneWidget);
    expect(find.text('Display name saved.'), findsOneWidget);
    await tap(tester, 'Explore demo groups');
    expect(find.text('Friday Dinner'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, 'Sign out');
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Your account'), findsNothing);
  });

  testWidgets('validates form and prevents duplicate in-flight login', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var requests = 0;
    final session = testSession(
      handler: (_) {
        requests++;
        return pending.future;
      },
    );
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    await tap(tester, 'Sign in');
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(requests, 0);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@example.invalid',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'synthetic passphrase!',
    );
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(requests, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    pending.complete(http.Response('{}', 401));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'alex@example.invalid',
    );
  });

  testWidgets('expiry removes a restored account and its token', (
    tester,
  ) async {
    final store = MemoryTokenStore()
      ..value = StoredSession(
        'token',
        DateTime.now().add(const Duration(seconds: 2)),
      );
    final session = testSession(store: store);
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text('Your session has ended. Please sign in again.'),
      findsOneWidget,
    );
    expect(store.value, isNull);
  });

  testWidgets('private account fits 320px with 200% text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = MemoryTokenStore()
      ..value = StoredSession(
        'token',
        DateTime.now().add(const Duration(minutes: 10)),
      );
    final session = testSession(store: store);
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.text('Your account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await session.signOut();
    await tester.pumpAndSettle();
  });
}

Future<void> tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
