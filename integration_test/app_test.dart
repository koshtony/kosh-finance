// Real-device/real-engine tests against the live API's seeded test tenant
// (see backend's seed_test_tenant management command). These need network
// access and a running Flutter engine, hence integration_test rather than
// plain flutter_test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

  await tester.enterText(find.widgetWithText(TextField, 'Username'), 'test_admin');
  await tester.enterText(find.widgetWithText(TextField, 'Password'), 'kosh-test-admin-1');
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pump();
  await _pumpUntilGone(tester, find.byType(LoginScreen));
  // HomeShell's own data load (over the network) finishes after the login
  // screen is gone — give it room before interacting with any page.
  await _pumpUntilGone(tester, find.byType(CircularProgressIndicator));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login screen renders with Kosh branding', (tester) async {
    await tester.pumpWidget(const KoshFinanceApp());
    await tester.pump();

    expect(find.text('Kosh Finance'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });

  testWidgets('Wrong password shows an error and does not log in', (tester) async {
    await tester.pumpWidget(const KoshFinanceApp());
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'test_admin');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'not-the-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await _pumpUntilFound(tester, find.textContaining('Incorrect username or password'));

    expect(find.textContaining('Incorrect username or password'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('test_admin logs in and can reach every section incl. Settings', (tester) async {
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

    expect(find.text('test_admin'), findsWidgets);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Add user'), findsOneWidget);
    expect(find.text('Income sources'), findsOneWidget);
    expect(find.text('Businesses'), findsOneWidget);
  });

  testWidgets('Can add a business, then log a daily sale for it', (tester) async {
    await _bootAndLogIn(tester);
    final businessName = 'Test Biz ${DateTime.now().millisecondsSinceEpoch}';

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Add business'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.widgetWithText(TextField, 'Business name'), businessName);
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await _pumpUntilGone(tester, find.text('Add business'));

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
