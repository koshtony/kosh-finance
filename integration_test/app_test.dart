// Real-device/real-engine tests for flows that touch sqflite. Plain
// flutter_test widget tests run inside a fake-async clock, and
// sqflite_common_ffi's internal lock-timeout Timer gets bound to that fake
// clock when I/O is kicked off from a widget build — it then never fires in
// any useful way, so DB-dependent flows (login, navigation after auth)
// effectively hang there. integration_test uses real time throughout, which
// matches how the shipped app actually runs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kosh_finance/main.dart';
import 'package:kosh_finance/screens/login_screen.dart';

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder, {int maxTries = 100}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder, {int maxTries = 100}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _bootAndLogIn(WidgetTester tester) async {
  await tester.pumpWidget(const KoshFinanceApp());
  await tester.pump();
  await _pumpUntilGone(tester, find.byType(CircularProgressIndicator));

  await tester.enterText(find.widgetWithText(TextField, 'Password'), 'admin');
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pump();
  await _pumpUntilGone(tester, find.byType(LoginScreen));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  testWidgets('Login screen renders with Kosh branding', (tester) async {
    await tester.pumpWidget(const KoshFinanceApp());
    await tester.pump();
    await _pumpUntilGone(tester, find.byType(CircularProgressIndicator));

    expect(find.text('Kosh Finance'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });

  testWidgets('Wrong password shows an error and does not log in', (tester) async {
    await tester.pumpWidget(const KoshFinanceApp());
    await tester.pump();
    await _pumpUntilGone(tester, find.byType(CircularProgressIndicator));

    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'not-the-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await _pumpUntilFound(tester, find.textContaining('Incorrect username or password'));

    expect(find.textContaining('Incorrect username or password'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Default admin logs in and can reach every section incl. Settings', (tester) async {
    await _bootAndLogIn(tester);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Kosh Finance'), findsOneWidget);

    for (final label in ['Sources', 'Business', 'Invest', 'Customers', 'Settings', 'Dashboard']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('Admin can open Settings and see the user directory', (tester) async {
    await _bootAndLogIn(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('admin'), findsWidgets);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Add user'), findsOneWidget);
    expect(find.text('Income sources'), findsOneWidget);
    expect(find.text('Businesses'), findsOneWidget);
    expect(find.text('Bubbles Lundry'), findsOneWidget);
    expect(find.text('Koshtech'), findsOneWidget);
  });

  testWidgets('Can log a daily sale for a business', (tester) async {
    await _bootAndLogIn(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Business'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Daily sales'));
    // The tab-switch slide animation needs to fully settle before the FAB's
    // hit-test region matches its final on-screen position.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Add daily sale'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount sold'), '2500');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _pumpUntilGone(tester, find.text('Add daily sale'));

    expect(find.textContaining('2,500'), findsWidgets);
  });
}
