import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/features/auth/screens/welcome_screen.dart';
import 'package:mobile/features/groups/screens/groups_screen.dart';

Future<void> selectMode(WidgetTester tester, String mode) async {
  await tester.tap(find.byTooltip('Appearance'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switches theme across routes without resetting account layout', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    await tester.ensureVisible(find.text('Preview create-account screen'));
    await tester.tap(find.text('Preview create-account screen'));
    await tester.pumpAndSettle();
    await selectMode(tester, 'Dark');
    expect(
      Theme.of(tester.element(find.byType(WelcomeScreen))).brightness,
      Brightness.dark,
    );
    expect(find.text('Confirm password'), findsOneWidget);
    await tester.ensureVisible(find.text('Explore demo'));
    await tester.tap(find.text('Explore demo'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(GroupsScreen))).brightness,
      Brightness.dark,
    );
    await selectMode(tester, 'Light');
    expect(
      Theme.of(tester.element(find.byType(GroupsScreen))).brightness,
      Brightness.light,
    );
    await selectMode(tester, 'System');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets(
    'system mode follows device brightness and explicit mode overrides it',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(WelcomeScreen))).brightness,
        Brightness.dark,
      );
      await selectMode(tester, 'Light');
      expect(
        Theme.of(tester.element(find.byType(WelcomeScreen))).brightness,
        Brightness.light,
      );
      await selectMode(tester, 'System');
      dispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(WelcomeScreen))).brightness,
        Brightness.light,
      );
    },
  );
}
