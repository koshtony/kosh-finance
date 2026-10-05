import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_repository.dart';
import 'services/auth_store.dart';
import 'services/finance_repository.dart';
import 'services/finance_store.dart';
import 'theme.dart';

void main() {
  // The sqflite plugin only registers a databaseFactory via platform
  // channels on Android/iOS. Desktop builds need the FFI backend instead.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const KoshFinanceApp());
}

class KoshFinanceApp extends StatelessWidget {
  const KoshFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceStore(FinanceRepository())..load()),
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
