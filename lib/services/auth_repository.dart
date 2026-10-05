import '../models/models.dart';
import 'api_client.dart';

/// Thrown by [AuthRepository.login] when the credentials are valid but the
/// account has no tenant membership yet (nothing for the app to show).
class NoTenantAccessException implements Exception {}

class AuthSession {
  final AppUser user;
  final int tenantId;
  AuthSession({required this.user, required this.tenantId});
}

List<String> _parseAllowedPages(dynamic value) => ((value as String?) ?? '')
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

AppUser _memberToAppUser(dynamic m, String username) => AppUser(
      id: m['id'] as int,
      username: username,
      passwordHash: '',
      passwordSalt: '',
      isAdmin: m['is_admin'] as bool,
      allowedPages: _parseAllowedPages(m['allowed_pages']),
    );

/// Talks to the Kosh API's token auth + tenant-membership endpoints.
/// [AppUser.id] holds the *membership* id (not the underlying Django user
/// id) since that's what the member-management endpoints are keyed on.
class AuthRepository {
  final _api = ApiClient.instance;

  /// Returns the signed-in session, or null for plain bad credentials.
  /// Throws [NoTenantAccessException] if the credentials are valid but the
  /// account isn't a member of any tenant.
  Future<AuthSession?> login(String username, String password) async {
    dynamic tokenRes;
    try {
      tokenRes = await _api.post('/auth/token/', {'username': username, 'password': password});
    } on ApiException {
      return null;
    }
    _api.token = tokenRes['token'] as String;

    final me = await _api.get('/me/') as Map<String, dynamic>;
    final memberships = (me['memberships'] as List).cast<Map<String, dynamic>>();
    if (memberships.isEmpty) {
      _api.reset();
      throw NoTenantAccessException();
    }

    final membership = memberships.first;
    final tenant = membership['tenant'] as Map<String, dynamic>;
    _api.tenantId = tenant['id'] as int;

    final user = AppUser(
      id: membership['id'] as int,
      username: me['username'] as String,
      passwordHash: '',
      passwordSalt: '',
      isAdmin: membership['is_admin'] as bool,
      allowedPages: _parseAllowedPages(membership['allowed_pages']),
    );
    return AuthSession(user: user, tenantId: tenant['id'] as int);
  }

  void logout() => _api.reset();

  int get _tid => _api.tenantId!;

  Future<List<AppUser>> getUsers() async {
    final rows = await _api.getAllPages('/tenants/$_tid/members/');
    final list = rows.map((m) => _memberToAppUser(m, m['username'] as String)).toList();
    list.sort((a, b) => a.username.compareTo(b.username));
    return list;
  }

  Future<int> createUser({
    required String username,
    required String password,
    required bool isAdmin,
    required List<String> allowedPages,
  }) async {
    final res = await _api.post('/tenants/$_tid/members/', {
      'username': username,
      'password': password,
      'role': isAdmin ? 'admin' : 'member',
      'allowed_pages': allowedPages.join(','),
    });
    return res['id'] as int;
  }

  Future<void> updatePermissions(int membershipId, {required bool isAdmin, required List<String> allowedPages}) async {
    await _api.patch('/tenants/$_tid/members/$membershipId/', {
      'role': isAdmin ? 'admin' : 'member',
      'allowed_pages': allowedPages.join(','),
    });
  }

  Future<void> changePassword(int membershipId, String newPassword) async {
    await _api.patch('/tenants/$_tid/members/$membershipId/', {'password': newPassword});
  }

  Future<int> countAdmins() async {
    final users = await getUsers();
    return users.where((u) => u.isAdmin).length;
  }

  Future<void> deleteUser(int membershipId) async {
    await _api.delete('/tenants/$_tid/members/$membershipId/');
  }
}
