import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kosh_finance/main.dart';

void main() {
  testWidgets('App boots to the login screen with Kosh branding', (tester) async {
    await tester.pumpWidget(const KoshFinanceApp());
    await tester.pump();

    expect(find.text('Kosh Finance'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
