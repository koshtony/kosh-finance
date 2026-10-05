import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_store.dart';
import '../services/finance_store.dart';
import '../theme.dart';
import '../widgets/bee_branding.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    return Scaffold(
      body: HoneycombBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BeeLogo(size: 84),
                    const SizedBox(height: 16),
                    const Text(
                      'Kosh Finance',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kBrandDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Track income, expenses, and the business — all in one hive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kNeutralColor),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              obscureText: _obscure,
                              onSubmitted: (_) => _submit(auth),
                            ),
                            if (auth.loginError != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                auth.loginError!,
                                style: const TextStyle(color: kWarningColor, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: auth.busy ? null : () => _submit(auth),
                                child: auth.busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Log in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'First time here? Default login is admin / admin — '
                      'change the password from Settings once you\'re in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: kNeutralColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(AuthStore auth) async {
    FocusScope.of(context).unfocus();
    final ok = await auth.login(_usernameController.text, _passwordController.text);
    if (ok && mounted) {
      // ignore: use_build_context_synchronously
      context.read<FinanceStore>().load();
    }
  }
}
