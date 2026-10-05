import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_store.dart';
import '../../theme.dart';

const Map<String, IconData> pageIcons = {
  'dashboard': Icons.dashboard_outlined,
  'employment': Icons.source_outlined,
  'business': Icons.storefront_outlined,
  'investments': Icons.trending_up_outlined,
  'customers': Icons.people_outline,
};

class _PermissionChecklist extends StatelessWidget {
  final bool isAdmin;
  final Set<String> allowed;
  final ValueChanged<bool> onAdminChanged;
  final void Function(String page, bool value) onPageChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  const _PermissionChecklist({
    required this.isAdmin,
    required this.allowed,
    required this.onAdminChanged,
    required this.onPageChanged,
    required this.onSelectAll,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isAdmin ? kHoneyLight.withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            secondary: Icon(Icons.shield_outlined, color: isAdmin ? kBrandDark : kNeutralColor),
            title: const Text('Admin (full access)', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
              'Can open every page and manage other users',
              style: TextStyle(fontSize: 12),
            ),
            value: isAdmin,
            onChanged: onAdminChanged,
          ),
        ),
        if (!isAdmin) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pages this user can open',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: allowed.length == kAppPageKeys.length ? null : onSelectAll,
                    child: const Text('Select all', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: allowed.isEmpty ? null : onClearAll,
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...kAppPageKeys.map((key) {
            final selected = allowed.contains(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? kHoneyLight.withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? kBrandColor : Colors.transparent, width: 1),
                ),
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  dense: true,
                  secondary: Icon(pageIcons[key] ?? Icons.circle_outlined, size: 20, color: kBrandDark),
                  title: Text(kAppPageLabels[key] ?? key, style: const TextStyle(fontWeight: FontWeight.w500)),
                  value: selected,
                  onChanged: (v) => onPageChanged(key, v ?? false),
                ),
              ),
            );
          }),
          if (allowed.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'No pages selected yet — this user won\'t be able to open anything.',
                style: TextStyle(fontSize: 11.5, color: kWarningColor),
              ),
            ),
        ],
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      obscureText: _obscure,
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
      builder: (ctx, setState) {
        final canCreate =
            !saving && usernameController.text.trim().isNotEmpty && passwordController.text.isNotEmpty;
        return AlertDialog(
          title: const Text('Add user'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _PasswordField(controller: passwordController, label: 'Temporary password'),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 2),
                  child: Text(
                    'They can change this from Settings after logging in.',
                    style: TextStyle(fontSize: 11, color: kNeutralColor),
                  ),
                ),
                const SizedBox(height: 14),
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
                  onSelectAll: () => setState(() => allowed.addAll(kAppPageKeys)),
                  onClearAll: () => setState(() => allowed.clear()),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: kWarningColor, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: !canCreate
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
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        );
      },
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: user.isAdmin ? kHoneyLight : const Color(0xFFF1F5F9),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kBrandDark, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(user.username, overflow: TextOverflow.ellipsis)),
          ],
        ),
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
                onSelectAll: () => setState(() => allowed.addAll(kAppPageKeys)),
                onClearAll: () => setState(() => allowed.clear()),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
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
                    final confirmed = await _confirmDeleteUser(ctx, user.username);
                    if (confirmed != true) return;
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
            child: saving
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<bool?> _confirmDeleteUser(BuildContext context, String username) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete user?'),
      content: Text('This removes "$username"\'s access permanently. They will no longer be able to log in.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kWarningColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
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
            _PasswordField(controller: controller, label: 'New password'),
            const SizedBox(height: 10),
            _PasswordField(controller: confirmController, label: 'Confirm new password'),
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
