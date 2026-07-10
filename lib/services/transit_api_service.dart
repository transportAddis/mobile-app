import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:mobile_app/services/api_exceptions.dart';
import 'package:mobile_app/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitApiService
//
// Wraps all passenger-facing transit endpoints. Every request attaches the
// JWT retrieved from [AuthService.instance.getToken()].
//
// Throws [ApiException] on:
//   • Non-2xx HTTP response
//   • Missing or expired JWT  (401 → ApiException.unauthorized)
//   • Network failure         (SocketException → ApiException.network)
//   • Malformed JSON          (FormatException  → ApiException.parse)
//
// NOTE: STANDALONE — not wired to any Provider or UI screen yet.
// Integration task will follow the demo.
// ─────────────────────────────────────────────────────────────────────────────

class TransitApiService {
  TransitApiService._();
  static final TransitApiService instance = TransitApiService._();

  static const String _baseUrl = 'https://back-end-zp70.onrender.com';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a raw JSON list of stations within [radius] metres of the
  /// given coordinates.
  ///
  /// Endpoint: GET /passenger/stations/nearby/
  ///   ?latitude=<lat>&longitude=<lng>&radius=<radius>
  ///
  /// Each list element is a raw [Map<String, dynamic>] from the server.
  /// The caller (or a future repository layer) is responsible for mapping
  /// these to domain models.
  Future<List<dynamic>> getNearbyStations({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    // FIX: Added trailing slash to satisfy Django APPEND_SLASH [12]
    final uri = Uri.parse('$_baseUrl/passenger/stations/nearby/').replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'radius': radius.toString(),
      },
    );

    final response = await _get(uri);
    return _asList(response);
  }

  /// Returns a raw JSON list of route options between the user's nearby
  /// stations and a specific destination station.
  ///
  /// Endpoint: POST /passenger/routes/search/
  /// Body:
  /// ```json
  /// {
  ///   "destinationStationId": "<id>",
  ///   "nearbyStationIds": ["<id1>", "<id2>"]
  /// }
  /// ```
  Future<List<dynamic>> searchRoutes({
    required String destinationStationId,
    required List<String> nearbyStationIds,
  }) async {
    // FIX: Added trailing slash to satisfy Django APPEND_SLASH [12]
    final uri = Uri.parse('$_baseUrl/passenger/routes/search/');

    final response = await _post(
      uri,
      body: {
        'destinationStationId': destinationStationId,
        'nearbyStationIds': nearbyStationIds,
      },
    );

    return _asList(response);
  }

  // ── Private HTTP helpers ──────────────────────────────────────────────────

  Future<dynamic> _get(Uri uri) async {
    final headers = await _authHeaders();

    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException.network();
    } on FormatException {
      throw ApiException.parse();
    }
  }

  Future<dynamic> _post(Uri uri, {required Map<String, dynamic> body}) async {
    final headers = await _authHeaders();

    try {
      final response = await http.post(
        uri,
        headers: headers,
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

  /// Builds headers including the Bearer token.
  ///
  /// Throws [ApiException.unauthorized] if no token is stored — this
  /// guards against calling protected endpoints before logging in.
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getToken();

    if (token == null || token.isEmpty) {
      throw ApiException.unauthorized();
    }

    return {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: ContentType.json.value,
      HttpHeaders.acceptHeader: ContentType.json.value,
    };
  }

  /// Decodes the response body and throws [ApiException] on non-2xx status.
  dynamic _handleResponse(http.Response response) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw ApiException.parse();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Extract the server's own error message when present.
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage =
          data['message'] as String? ??
          data['detail'] as String? ??
          data['error'] as String?;
    }

    throw ApiException.fromStatus(response.statusCode, serverMessage);
  }

  /// Coerces a decoded JSON value into a [List].
  ///
  /// Some endpoints wrap the list in a top-level object like
  /// `{"results": [...]}`. This helper handles both shapes gracefully.
  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;

    // Common wrapper keys: 'results', 'data', 'stations', 'routes'
    if (data is Map<String, dynamic>) {
      for (final key in ['results', 'data', 'stations', 'routes']) {
        if (data[key] is List) return data[key] as List<dynamic>;
      }
    }

    throw ApiException.parse();
  }
}
