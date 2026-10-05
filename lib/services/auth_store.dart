import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
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

    try {
      final session = await repo.login(username.trim(), password);
      busy = false;
      if (session == null) {
        loginError = 'Incorrect username or password.';
        notifyListeners();
        return false;
      }
      currentUser = session.user;
      notifyListeners();
      await refreshUsers();
      return true;
    } on NoTenantAccessException {
      busy = false;
      loginError = 'Your account has no tenant access yet. Ask an admin to add you.';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      busy = false;
      loginError = e.message;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    repo.logout();
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
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not create user — username may already exist.';
    }
  }

  Future<String?> updatePermissions(AppUser user, {required bool isAdmin, required List<String> allowedPages}) async {
    if (user.isAdmin && !isAdmin) {
      final admins = await repo.countAdmins();
      if (admins <= 1) return 'At least one admin account must remain.';
    }
    try {
      await repo.updatePermissions(user.id!, isAdmin: isAdmin, allowedPages: allowedPages);
      await refreshUsers();
      if (currentUser?.id == user.id) {
        currentUser = users.firstWhere((u) => u.id == user.id);
        notifyListeners();
      }
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteUser(AppUser user) async {
    if (user.isAdmin) {
      final admins = await repo.countAdmins();
      if (admins <= 1) return 'At least one admin account must remain.';
    }
    if (user.id == currentUser?.id) {
      return 'You cannot delete the account you are logged in as.';
    }
    try {
      await repo.deleteUser(user.id!);
      await refreshUsers();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> changeOwnPassword(String newPassword) async {
    if (currentUser == null) return;
    await repo.changePassword(currentUser!.id!, newPassword);
  }
}
