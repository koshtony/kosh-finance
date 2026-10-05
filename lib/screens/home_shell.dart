import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_store.dart';
import '../services/finance_store.dart';
import 'business_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'employment_screen.dart';
import 'investments_screen.dart';
import 'settings_screen.dart';

class _PageEntry {
  final String key;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  const _PageEntry(this.key, this.label, this.icon, this.selectedIcon, this.screen);
}

const _allPages = [
  _PageEntry('dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard, DashboardScreen()),
  _PageEntry('employment', 'Sources', Icons.source_outlined, Icons.source, EmploymentScreen()),
  _PageEntry('business', 'Business', Icons.storefront_outlined, Icons.storefront, BusinessScreen()),
  _PageEntry('investments', 'Invest', Icons.trending_up_outlined, Icons.trending_up, InvestmentsScreen()),
  _PageEntry('customers', 'Customers', Icons.people_outline, Icons.people, CustomersScreen()),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final auth = context.watch<AuthStore>();
    final user = auth.currentUser;

    if (store.loading && store.periodTotals.isEmpty && store.customers.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final pages = _allPages.where((p) => user.canAccess(p.key)).toList();
    final screens = [...pages.map((p) => p.screen), const SettingsScreen()];
    final index = _index.clamp(0, screens.length - 1);

    if (pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kosh Finance')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40, color: Colors.black38),
                const SizedBox(height: 12),
                const Text(
                  'No pages have been granted to your account yet.\nAsk an admin to set your permissions in Settings.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          ...pages.map((p) => NavigationDestination(
                icon: Icon(p.icon),
                selectedIcon: Icon(p.selectedIcon),
                label: p.label,
              )),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
