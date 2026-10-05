import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Thin HTTP/JSON wrapper around the Kosh API (Django REST Framework).
/// Holds the current session's auth token and active tenant in memory —
/// matching the app's existing behaviour of asking for credentials on
/// every fresh start rather than persisting a session.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  // Override at build/run time with --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  // for local backend testing; defaults to the hosted deployment otherwise.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kosh-finance-production.up.railway.app/api',
  );

  String? token;
  int? tenantId;

  void reset() {
    token = null;
    tenantId = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) => _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  /// Follows DRF's `{results, next}` pagination until exhausted. Fine for
  /// this app's list sizes — no need for incremental/lazy loading.
  Future<List<dynamic>> getAllPages(String path) async {
    final results = <dynamic>[];
    Uri? uri = _uri(path);
    while (uri != null) {
      final decoded = await _send(() => http.get(uri!, headers: _headers));
      if (decoded is List) {
        results.addAll(decoded);
        break;
      }
      results.addAll((decoded['results'] as List?) ?? const []);
      final next = decoded['next'] as String?;
      uri = next == null ? null : Uri.parse(next);
    }
    return results;
  }

  Future<dynamic> _send(Future<http.Response> Function() fn) async {
    final http.Response res;
    try {
      res = await fn();
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException(_extractError(res));
  }

  String _extractError(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        if (decoded['detail'] is String) return decoded['detail'] as String;
        for (final value in decoded.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String) return value;
        }
      }
    } catch (_) {
      // Fall through to the generic message below.
    }
    return 'Request failed (${res.statusCode}).';
  }
}

double? toDoubleOrNull(dynamic v) => v == null ? null : double.tryParse(v.toString());

double toDoubleOr(dynamic v, double fallback) => v == null ? fallback : (double.tryParse(v.toString()) ?? fallback);
