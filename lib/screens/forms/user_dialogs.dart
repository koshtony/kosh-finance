import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_store.dart';
import '../../theme.dart';

class _PermissionChecklist extends StatelessWidget {
  final bool isAdmin;
  final Set<String> allowed;
  final ValueChanged<bool> onAdminChanged;
  final void Function(String page, bool value) onPageChanged;

  const _PermissionChecklist({
    required this.isAdmin,
    required this.allowed,
    required this.onAdminChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Admin (full access)'),
          subtitle: const Text('Admins can access every page and manage users'),
          value: isAdmin,
          onChanged: onAdminChanged,
        ),
        if (!isAdmin) ...[
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 2),
            child: Text('Pages this user can open', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          ...kAppPageKeys.map((key) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(kAppPageLabels[key] ?? key),
                value: allowed.contains(key),
                onChanged: (v) => onPageChanged(key, v ?? false),
              )),
        ],
      ],
    );
  }
}

void showCreateUserDialog(BuildContext context, AuthStore auth) {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isAdmin = false;
  final allowed = <String>{};
  bool saving = false;
  String? error;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Add user'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Temporary password'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              _PermissionChecklist(
                isAdmin: isAdmin,
                allowed: allowed,
                onAdminChanged: (v) => setState(() => isAdmin = v),
                onPageChanged: (page, v) => setState(() {
                  if (v) {
                    allowed.add(page);
                  } else {
                    allowed.remove(page);
                  }
                }),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: kWarningColor, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    final err = await auth.createUser(
                      username: usernameController.text,
                      password: passwordController.text,
                      isAdmin: isAdmin,
                      allowedPages: allowed.toList(),
                    );
                    if (err != null) {
                      setState(() {
                        error = err;
                        saving = false;
                      });
                    } else if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}

void showEditPermissionsDialog(BuildContext context, AuthStore auth, AppUser user) {
  bool isAdmin = user.isAdmin;
  final allowed = {...user.allowedPages};
  bool saving = false;
  String? error;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(user.username),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PermissionChecklist(
                isAdmin: isAdmin,
                allowed: allowed,
                onAdminChanged: (v) => setState(() => isAdmin = v),
                onPageChanged: (page, v) => setState(() {
                  if (v) {
                    allowed.add(page);
                  } else {
                    allowed.remove(page);
                  }
                }),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: kWarningColor, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kWarningColor),
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    final err = await auth.deleteUser(user);
                    if (err != null) {
                      setState(() {
                        error = err;
                        saving = false;
                      });
                    } else if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: const Text('Delete'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    final err = await auth.updatePermissions(user, isAdmin: isAdmin, allowedPages: allowed.toList());
                    if (err != null) {
                      setState(() {
                        error = err;
                        saving = false;
                      });
                    } else if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void showChangePasswordDialog(BuildContext context, AuthStore auth) {
  final controller = TextEditingController();
  final confirmController = TextEditingController();
  String? error;
  bool saving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              obscureText: true,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: kWarningColor, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (controller.text.isEmpty) {
                      setState(() => error = 'Password cannot be empty.');
                      return;
                    }
                    if (controller.text != confirmController.text) {
                      setState(() => error = 'Passwords do not match.');
                      return;
                    }
                    setState(() => saving = true);
                    await auth.changeOwnPassword(controller.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
