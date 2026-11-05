import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/prototype/demo_data.dart';
import 'package:mobile/features/bills/screens/add_bill_screen.dart';
import 'package:mobile/features/bills/screens/sample_bill_screen.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/screens/welcome_screen.dart';
import 'package:mobile/features/bills/screens/draft_screen.dart';
import 'package:mobile/features/groups/screens/groups_screen.dart';
import 'package:mobile/features/groups/screens/group_screen.dart';
import 'package:mobile/features/groups/screens/name_screen.dart';
import 'package:mobile/features/groups/screens/participants_screen.dart';

import 'auth_test_helpers.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('account layouts switch and demo navigation shows sample bill', (
    tester,
  ) async {
    final session = testSession();
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    await tapText(tester, 'New here? Create account');
    expect(find.text('Confirm password'), findsOneWidget);
    await tapText(tester, 'Explore demo');
    await tapText(tester, 'Friday Dinner');
    await tapText(tester, 'Dinner');
    expect(find.text('Equal shares - sample'), findsOneWidget);
    expect(find.text('HKD 33.34'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Manage participants'), findsOneWidget);
  });

  testWidgets('creates an in-memory group and adds a participant', (
    tester,
  ) async {
    final session = testSession();
    addTearDown(() {
      session.dispose();
      session.api.close();
    });
    await tester.pumpWidget(MyApp(session: session));
    await tester.pumpAndSettle();
    await tapText(tester, 'Explore demo');
    await tapText(tester, 'Create demo group');
    await tapText(tester, 'Create demo group');
    expect(find.text('Enter a name.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Test dinner');
    await tapText(tester, 'Create demo group');
    expect(
      find.text('Add participants before recording a bill.'),
      findsOneWidget,
    );
    await tapText(tester, 'Manage participants');
    await tapText(tester, 'Add participant');
    await tester.enterText(find.byType(TextFormField), 'Morgan');
    await tapText(tester, 'Add demo participant');
    await tapText(tester, 'Morgan');
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets(
    'bill form rejects invalid input and previews payer-excluded draft',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddBillScreen(group: demoGroups().first)),
      );
      await tapText(tester, 'Preview bill (not saved)');
      expect(find.text('Select at least one person.'), findsOneWidget);
      expect(find.text('Choose one payer.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Lunch');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alex').last);
      await tester.pumpAndSettle();
      await tapText(tester, 'Bea');
      await tapText(tester, 'Preview bill (not saved)');
      expect(
        find.text('Enter between HKD 0.01 and HKD 21,474,836.47.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField).at(1), '10.01');
      await tapText(tester, 'Preview bill (not saved)');
      expect(find.text('Bill preview'), findsOneWidget);
      expect(find.text('Payer is not included in the split.'), findsOneWidget);
      expect(find.text('HKD 10.01'), findsOneWidget);
    },
  );

  testWidgets('sample details fit narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SampleBillScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  final layouts = <String, Widget Function()>{
    'welcome': () => const WelcomeScreen(),
    'groups': () => const GroupsScreen(),
    'group': () => GroupScreen(group: demoGroups().first),
    'participants': () => ParticipantsScreen(group: demoGroups().first),
    'create group': () => const NameScreen(group: true),
    'add participant': () => const NameScreen(group: false),
    'add bill': () => AddBillScreen(group: demoGroups().first),
    'sample bill': () => const SampleBillScreen(),
    'draft': () => DraftScreen(
      description: 'Lunch with friends',
      total: '100.00',
      payer: 'Alex',
      participants: const ['Bea', 'Chan'],
      date: DateTime(2026, 11, 5),
    ),
  };

  for (final layout in layouts.entries) {
    testWidgets('${layout.key} uses app theme at 320px and 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: layout.value(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('identifying yourself can be cleared without changing names', (
    tester,
  ) async {
    final group = demoGroups().first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ParticipantsScreen(group: group),
      ),
    );
    await tapText(tester, 'Bea');
    expect(group.self, 'Bea');
    await tapText(tester, 'Bea');
    expect(group.self, isNull);
    expect(group.participants, ['Alex', 'Bea', 'Chan']);
  });
}
