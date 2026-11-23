import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/state/session_scope.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('app uses the configured backend origin', (tester) async {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final session = tester
        .widget<SessionScope>(find.byType(SessionScope))
        .notifier!;
    expect(
      session.api.client.baseUrl,
      const String.fromEnvironment(
        'EXPECTED_API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
