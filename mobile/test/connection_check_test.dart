import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/api/health_api.dart';
import 'package:mobile/widgets/connection_check.dart';

void main() {
  testWidgets(
    'shows idle, loading, and connected states without duplicate requests',
    (tester) async {
      final pending = Completer<http.Response>();
      var requests = 0;
      final api = HealthApi(
        baseUrl: 'http://localhost:3000',
        client: MockClient((_) {
          requests++;
          return pending.future;
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ConnectionCheck(api: api)),
        ),
      );
      expect(find.text('Not checked yet.'), findsOneWidget);
      expect(requests, 0);
      await tester.tap(find.text('Check connection'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(requests, 1);
      pending.complete(http.Response('{"status":"ok","database":"up"}', 200));
      await tester.pumpAndSettle();
      expect(
        find.text('Connected: backend and PostgreSQL are ready.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows database error and allows a successful retry', (
    tester,
  ) async {
    var requests = 0;
    final api = HealthApi(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) async {
        requests++;
        return requests == 1
            ? http.Response('{"status":"error","database":"down"}', 503)
            : http.Response('{"status":"ok","database":"up"}', 200);
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConnectionCheck(api: api)),
      ),
    );
    await tester.tap(find.text('Check connection'));
    await tester.pumpAndSettle();
    expect(
      find.text('Backend is reachable, but PostgreSQL is unavailable.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Check connection'));
    await tester.pumpAndSettle();
    expect(
      find.text('Connected: backend and PostgreSQL are ready.'),
      findsOneWidget,
    );
    expect(requests, 2);
  });

  testWidgets('finishing after disposal does not update disposed state', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    final api = HealthApi(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) => pending.future),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConnectionCheck(api: api)),
      ),
    );
    await tester.tap(find.text('Check connection'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete(http.Response('{"status":"ok","database":"up"}', 200));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports missing API configuration', (tester) async {
    final api = HealthApi(
      baseUrl: '',
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConnectionCheck(api: api)),
      ),
    );
    expect(find.text('Backend URL is not configured.'), findsOneWidget);
    await tester.tap(find.text('Check connection'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Set API_BASE_URL'), findsOneWidget);
  });
}
