import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_store.dart';
import '../services/finance_store.dart';
import '../theme.dart';
import 'forms/user_dialogs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final store = context.watch<FinanceStore>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: kHoneyLight,
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: kBrandDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          user.isAdmin ? 'Administrator' : 'Standard user',
                          style: const TextStyle(fontSize: 12, color: kNeutralColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: const Text('Change password'),
                  onTap: () => showChangePasswordDialog(context, auth),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: kWarningColor),
                  title: const Text('Log out', style: TextStyle(color: kWarningColor)),
                  onTap: () => auth.logout(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Income sources', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              TextButton.icon(
                onPressed: () => _showAddIncomeSourceDialog(context, store),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add source'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Income is no longer limited to Employment — add any income stream '
            '(Freelance, Rental, Side Gig...) to track it from the Sources page.',
            style: TextStyle(fontSize: 11, color: kNeutralColor),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: store.incomeSources.isEmpty
                  ? const Text('No income sources yet', style: TextStyle(color: kNeutralColor, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: store.incomeSources
                          .map((s) => InputChip(
                                label: Text(s.name),
                                onDeleted: () => _deleteIncomeSource(context, store, s),
                                deleteIconColor: kWarningColor,
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Businesses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              TextButton.icon(
                onPressed: () => _showAddBusinessDialog(context, store),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add business'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Add a new business here so it shows up on the Business page before you\'ve '
            'logged any revenue, expenses, or daily sales for it.',
            style: TextStyle(fontSize: 11, color: kNeutralColor),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: store.businesses.isEmpty
                  ? const Text('No businesses yet', style: TextStyle(color: kNeutralColor, fontSize: 13))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: store.businesses
                          .map((b) => InputChip(
                                label: Text(b.name),
                                onDeleted: () => _deleteBusiness(context, store, b),
                                deleteIconColor: kWarningColor,
                              ))
                          .toList(),
                    ),
            ),
          ),
          if (user.isAdmin) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Users', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                TextButton.icon(
                  onPressed: () => showCreateUserDialog(context, auth),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Add user'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Card(
              child: Column(
                children: [
                  for (final u in auth.users) ...[
                    _UserRow(user: u, auth: auth),
                    if (u != auth.users.last) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAddIncomeSourceDialog(BuildContext context, FinanceStore store) {
    final controller = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add income source'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Name (e.g. Freelance, Rental)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final err = await store.addIncomeSource(controller.text);
                if (err != null) {
                  setState(() => error = err);
                } else if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteIncomeSource(BuildContext context, FinanceStore store, IncomeSource source) async {
    final err = await store.deleteIncomeSource(source);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _showAddBusinessDialog(BuildContext context, FinanceStore store) {
    final controller = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add business'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Business name',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final err = await store.addBusiness(controller.text);
                if (err != null) {
                  setState(() => error = err);
                } else if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBusiness(BuildContext context, FinanceStore store, BusinessEntity business) async {
    final err = await store.deleteBusiness(business);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final AuthStore auth;
  const _UserRow({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    final pages = user.isAdmin
        ? 'All pages'
        : (user.allowedPages.isEmpty
            ? 'No pages granted'
            : user.allowedPages.map((p) => kAppPageLabels[p] ?? p).join(', '));

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isAdmin ? kHoneyLight : const Color(0xFFF1F5F9),
        child: Icon(
          user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
          size: 18,
          color: kBrandDark,
        ),
      ),
      title: Text(user.username),
      subtitle: Text(pages, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showEditPermissionsDialog(context, auth, user),
    );
  }
}
