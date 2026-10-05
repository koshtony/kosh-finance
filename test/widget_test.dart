import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kosh_finance/main.dart';

// This file sticks to assertions that don't depend on FinanceStore/AuthStore
// finishing their sqflite I/O: sqflite_common_ffi's internal lock-timeout
// Timer gets bound to flutter_test's fake-async clock when I/O starts from a
// widget build, which makes it hang here in practice. DB-dependent flows
// (login, navigating the app, daily sales) are covered for real in
// integration_test/app_test.dart, which runs on a real engine with real time.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App boots to the login screen with Kosh branding', (tester) async {
    await tester.pumpWidget(const KoshFinanceApp());
    await tester.pump();

    expect(find.text('Kosh Finance'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
