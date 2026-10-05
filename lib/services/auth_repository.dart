import '../db/db_helper.dart';
import '../models/models.dart';
import '../utils/password_utils.dart';

class AuthRepository {
  final _dbh = DbHelper.instance;

  Future<List<AppUser>> getUsers() async {
    final db = await _dbh.database;
    final rows = await db.query('users', orderBy: 'username');
    return rows.map(AppUser.fromMap).toList();
  }

  /// Returns the matching user if the credentials are correct, else null.
  Future<AppUser?> authenticate(String username, String password) async {
    final db = await _dbh.database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    final user = AppUser.fromMap(rows.first);
    if (verifyPassword(password, user.passwordSalt, user.passwordHash)) {
      return user;
    }
    return null;
  }

  Future<int> createUser({
    required String username,
    required String password,
    required bool isAdmin,
    required List<String> allowedPages,
  }) async {
    final db = await _dbh.database;
    final salt = generateSalt();
    return db.insert('users', {
      'username': username,
      'passwordHash': hashPassword(password, salt),
      'passwordSalt': salt,
      'isAdmin': isAdmin ? 1 : 0,
      'allowedPages': allowedPages.join(','),
    });
  }

  Future<void> updatePermissions(int userId, {required bool isAdmin, required List<String> allowedPages}) async {
    final db = await _dbh.database;
    await db.update(
      'users',
      {'isAdmin': isAdmin ? 1 : 0, 'allowedPages': allowedPages.join(',')},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> changePassword(int userId, String newPassword) async {
    final db = await _dbh.database;
    final salt = generateSalt();
    await db.update(
      'users',
      {'passwordHash': hashPassword(newPassword, salt), 'passwordSalt': salt},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> countAdmins() async {
    final db = await _dbh.database;
    final rows = await db.query('users', where: 'isAdmin = 1');
    return rows.length;
  }

  Future<void> deleteUser(int id) async {
    final db = await _dbh.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
