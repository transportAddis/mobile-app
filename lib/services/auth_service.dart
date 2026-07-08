import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/services/api_exceptions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService
//
// Handles JWT-based authentication against the Smart Transit backend.
// Token is persisted in SharedPreferences under [_kTokenKey].
//
// NOTE: This service is STANDALONE. It is not wired to any Provider or UI
// screen yet. It will be integrated in a future task after the demo.
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _baseUrl = 'https://back-end-zp70.onrender.com';
  static const String _kTokenKey = 'auth_token';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Authenticates the user and persists the returned JWT.
  ///
  /// Throws [ApiException] on any non-200 response or network failure.
  Future<void> login({required String email, required String password}) async {
    final response = await _post(
      '/auth/signin/',
      body: {'email': email.trim(), 'password': password},
    );

    final token = _extractToken(response);
    await _saveToken(token);
  }

  /// Registers a new user and persists the returned JWT.
  ///
  /// [fullName] is split on the first space to produce [firstName] and
  /// [lastName] as required by the /auth/signup/ contract.
  /// If [fullName] contains no space, the entire string is used as
  /// [firstName] and [lastName] is sent as an empty string.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final parts = fullName.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final response = await _post(
      '/auth/signup/',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email.trim(),
        'password': password,
      },
    );

    final token = _extractToken(response);
    await _saveToken(token);
  }

  /// Removes the stored JWT. Call this on user-initiated logout.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  /// Returns the stored JWT, or null if the user is not authenticated.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }

  /// Convenience: returns true when a token is present in storage.
  Future<bool> isLoggedIn() async => (await getToken()) != null;

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Executes a POST request and returns the decoded JSON body as a [Map].
  ///
  /// Throws [ApiException] on HTTP errors, network failures, and parse errors.
  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, String> body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final response = await http.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.value,
          HttpHeaders.acceptHeader: ContentType.json.value,
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException.network();
    } on FormatException {
      throw ApiException.parse();
    }
  }

  /// Decodes the HTTP response and throws [ApiException] on non-2xx status.
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException.parse();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Surface the server's own error message when available.
    final serverMessage =
        data['message'] as String? ??
        data['detail'] as String? ??
        data['error'] as String?;

    throw ApiException.fromStatus(response.statusCode, serverMessage);
  }

  /// Extracts the JWT from the decoded response body.
  ///
  /// Looks for common token field names: 'token', 'access', 'accessToken'.
  String _extractToken(Map<String, dynamic> body) {
    final token =
        body['token'] as String? ??
        body['access'] as String? ??
        body['accessToken'] as String?;

    if (token == null || token.isEmpty) {
      throw ApiException.parse();
    }

    return token;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }
}
