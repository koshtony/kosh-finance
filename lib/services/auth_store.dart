import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'auth_repository.dart';

/// Holds the current session and the admin-only user directory. Login state
/// lives in memory only (not persisted), so the app asks for credentials on
/// every fresh start — a reasonable default for a local finance app.
class AuthStore extends ChangeNotifier {
  final AuthRepository repo;
  AuthStore(this.repo);

  AppUser? currentUser;
  List<AppUser> users = [];
  String? loginError;
  bool busy = false;

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<bool> login(String username, String password) async {
    busy = true;
    loginError = null;
    notifyListeners();

    final user = await repo.authenticate(username.trim(), password);
    busy = false;
    if (user == null) {
      loginError = 'Incorrect username or password.';
      notifyListeners();
      return false;
    }
    currentUser = user;
    notifyListeners();
    await refreshUsers();
    return true;
  }

  void logout() {
    currentUser = null;
    users = [];
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    if (!isAdmin) return;
    users = await repo.getUsers();
    notifyListeners();
  }

  Future<String?> createUser({
    required String username,
    required String password,
    required bool isAdmin,
    required List<String> allowedPages,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Username and password are required.';
    }
    try {
      await repo.createUser(
        username: username.trim(),
        password: password,
        isAdmin: isAdmin,
        allowedPages: allowedPages,
      );
      await refreshUsers();
      return null;
    } catch (e) {
      return 'Could not create user — username may already exist.';
    }
  }

  Future<String?> updatePermissions(AppUser user, {required bool isAdmin, required List<String> allowedPages}) async {
    if (user.isAdmin && !isAdmin) {
      final admins = await repo.countAdmins();
      if (admins <= 1) return 'At least one admin account must remain.';
    }
    await repo.updatePermissions(user.id!, isAdmin: isAdmin, allowedPages: allowedPages);
    await refreshUsers();
    if (currentUser?.id == user.id) {
      currentUser = users.firstWhere((u) => u.id == user.id);
      notifyListeners();
    }
    return null;
  }

  Future<String?> deleteUser(AppUser user) async {
    if (user.isAdmin) {
      final admins = await repo.countAdmins();
      if (admins <= 1) return 'At least one admin account must remain.';
    }
    if (user.id == currentUser?.id) {
      return 'You cannot delete the account you are logged in as.';
    }
    await repo.deleteUser(user.id!);
    await refreshUsers();
    return null;
  }

  Future<void> changeOwnPassword(String newPassword) async {
    if (currentUser == null) return;
    await repo.changePassword(currentUser!.id!, newPassword);
  }
}
