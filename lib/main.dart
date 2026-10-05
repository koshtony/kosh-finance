import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_repository.dart';
import 'services/auth_store.dart';
import 'services/finance_repository.dart';
import 'services/finance_store.dart';
import 'theme.dart';

void main() {
  runApp(const KoshFinanceApp());
}

class KoshFinanceApp extends StatelessWidget {
  const KoshFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Loaded on demand once login picks a tenant — see LoginScreen._submit.
        ChangeNotifierProvider(create: (_) => FinanceStore(FinanceRepository())),
        ChangeNotifierProvider(create: (_) => AuthStore(AuthRepository())),
      ],
      child: MaterialApp(
        title: 'Kosh Finance',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}
