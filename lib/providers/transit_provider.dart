import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';

import 'package:mobile_app/models/nearby_station.dart';
import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/services/transit_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitProvider
//
// searchRoutes() calls the live backend and parses its nested-segment JSON
// shape into flat TransitRoute.coordinates lists. Any failure — empty
// result, network error, or malformed JSON — falls back to 3 hand-picked
// mock Addis Ababa paths so the map is never left blank.
// ─────────────────────────────────────────────────────────────────────────────

class TransitProvider extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────

  List<TransitRoute> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<NearbyStation> _nearbyStations = [];
  bool _isLoadingStations = false;
  String? _stationsError;

  // ── Public getters ─────────────────────────────────────────────────────────

  List<TransitRoute> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasRoutes => _routes.isNotEmpty;

  List<NearbyStation> get nearbyStations => List.unmodifiable(_nearbyStations);
  bool get isLoadingStations => _isLoadingStations;
  String? get stationsError => _stationsError;
  bool get hasNearbyStations => _nearbyStations.isNotEmpty;

  // ── Fetch: initial mock routes (unchanged entry point) ─────────────────────

  /// Populates [routes] with the same fallback dataset used by [searchRoutes]
  /// when the API is unreachable. Kept for the initial app-open state, before
  /// the user has picked a destination.
  Future<void> fetchMockData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _routes = _buildFallbackRoutes();
    } catch (e, s) {
      _error = 'Failed to load data.';
      debugPrint('[TransitProvider] fetchMockData error: $e\n$s');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch: nearby stations (500 m → 750 m fallback, unchanged) ────────────

  Future<void> fetchNearbyStations(double lat, double lng) async {
    _isLoadingStations = true;
    _stationsError = null;
    _nearbyStations = [];
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      var stations = _mockStations(500);

      if (stations.length <= 2) {
        await Future.delayed(const Duration(milliseconds: 400));
        stations = _mockStations(750);
      }

      if (stations.isEmpty) {
        _stationsError = 'No stations found near you.';
      } else {
        _nearbyStations = stations;
      }
    } catch (e, stack) {
      _stationsError = 'Could not load nearby stations.';
      debugPrint('[TransitProvider] fetchNearbyStations error: $e\n$stack');
    } finally {
      _isLoadingStations = false;
      notifyListeners();
    }
  }

  // ── Fetch: live route search (NEW) ──────────────────────────────────────────

  /// Calls the backend's route-search endpoint and parses the result into
  /// [TransitRoute] objects carrying real map coordinates.
  ///
  /// Backend response shape: `List<List<Map<String, dynamic>>>` — an array
  /// of alternative paths, each path being an ordered list of route segments.
  ///
  /// Fail-safe: on an empty response, a network exception, or any parsing
  /// failure, this method logs a debug message and loads 3 mock Addis Ababa
  /// paths instead of leaving [routes] empty. The map always has something
  /// to show.
  Future<void> searchRoutes(
    String destinationId,
    List<String> nearbyIds,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawPaths = await TransitApiService.instance.searchRoutes(
        destinationStationId: destinationId,
        nearbyStationIds: nearbyIds,
      );

      if (rawPaths.isEmpty) {
        debugPrint(
          '[TransitProvider] searchRoutes returned an empty list — '
          'loading mock fallback paths.',
        );
        _routes = _buildFallbackRoutes();
      } else {
        final parsed = _parseRoutesFromApi(rawPaths);
        if (parsed.isEmpty) {
          // Every path in the response was malformed — same fail-safe.
          debugPrint(
            '[TransitProvider] searchRoutes parsed 0 usable routes — '
            'loading mock fallback paths.',
          );
          _routes = _buildFallbackRoutes();
        } else {
          _routes = parsed;
        }
      }
    } catch (e, stack) {
      // Covers ApiException (network/HTTP), SocketException, FormatException,
      // and any unexpected cast failure during parsing.
      debugPrint(
        '[TransitProvider] searchRoutes failed ($e) — '
        'loading mock fallback paths.\n$stack',
      );
      _routes = _buildFallbackRoutes();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── JSON parsing (CRITICAL PATH) ────────────────────────────────────────────

  /// Converts the raw `List<List<Map>>` API response into [TransitRoute]s.
  ///
  /// For each path:
  ///   1. coordinates[0]  = segments.first.originStation      (lat/lng parsed)
  ///   2. coordinates[1+] = every segment's destinationStation, in order
  ///   3. Route-level metadata (name, queueLevel, fareInfo, etaMinutes) is
  ///      read from the FIRST segment — the assumption is that these fields
  ///      describe the route as a whole and are repeated on every segment,
  ///      or at minimum present on the first one. If your backend contract
  ///      differs (e.g. metadata lives on a separate top-level object),
  ///      update `_parseRoutesFromApi` accordingly.
  ///   4. A malformed individual path is skipped (not fatal) so one bad
  ///      entry doesn't blank out the other valid route options.
  static List<TransitRoute> _parseRoutesFromApi(List<dynamic> rawPaths) {
    final routes = <TransitRoute>[];

    for (var i = 0; i < rawPaths.length; i++) {
      try {
        final segments = (rawPaths[i] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        if (segments.isEmpty) continue;

        final coordinates = <LatLng>[];
        final stopNames = <String>[];

        // First point: originStation of the first segment.
        final firstOrigin =
            segments.first['originStation'] as Map<String, dynamic>;
        coordinates.add(_parseLatLng(firstOrigin));
        stopNames.add(_stationName(firstOrigin));

        // Every segment contributes its destinationStation as the next point.
        for (final segment in segments) {
          final dest = segment['destinationStation'] as Map<String, dynamic>;
          coordinates.add(_parseLatLng(dest));
          stopNames.add(_stationName(dest));
        }

        final meta = segments.first;

        routes.add(
          TransitRoute(
            id: (meta['id'] ?? meta['routeId'] ?? 'route_$i').toString(),
            name: (meta['name'] as String?) ?? 'Route ${i + 1}',
            // Bus-only system — default to Smart Bus if the field is absent.
            type: (meta['type'] as String?) ?? 'Smart Bus',
            etaMinutes: _parseEta(meta['etaMinutes']),
            // fareInfo (backend) -> fareAmount (model)
            fareAmount: (meta['fareInfo'] as String?) ?? 'ETB —',
            stationQueueLevel: _parseCrowdLevel(meta['queueLevel']),
            // NOTE: backend contract doesn't yet specify a vehicle-occupancy
            // field name. Checked against 'occupancyLevel' defensively;
            // defaults to medium until confirmed with the backend team.
            vehicleOccupancyLevel: _parseCrowdLevel(meta['occupancyLevel']),
            routeColor: _kRoutePalette[i % _kRoutePalette.length],
            stationNames: stopNames,
            coordinates: coordinates,
          ),
        );
      } catch (e) {
        debugPrint('[TransitProvider] Skipped malformed path at index $i: $e');
        continue;
      }
    }

    return routes;
  }

  /// Parses a station map's latitude/longitude, both sent as Strings by the
  /// backend, into a [LatLng] via `double.parse` as specified.
  static LatLng _parseLatLng(Map<String, dynamic> station) {
    final lat = double.parse(station['latitude'] as String);
    final lng = double.parse(station['longitude'] as String);
    return LatLng(lat, lng);
  }

  static String _stationName(Map<String, dynamic> station) =>
      (station['name'] as String?) ?? 'Stop';

  static int _parseEta(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 10;
    return 10;
  }

  static CrowdLevel _parseCrowdLevel(dynamic value) {
    if (value is String) {
      return switch (value.toLowerCase()) {
        'low' => CrowdLevel.low,
        'high' => CrowdLevel.high,
        _ => CrowdLevel.medium,
      };
    }
    return CrowdLevel.medium;
  }

  // ── Mock fallback data ──────────────────────────────────────────────────────

  /// Distinct colours assigned client-side by route index — the backend does
  /// not send colours, that remains a UI concern.
  static const List<Color> _kRoutePalette = [
    Color(0xFFDE613B), // terracotta (brand primary)
    Color(0xFF00695C), // deep teal
    Color(0xFF6A1B9A), // deep purple
    Color(0xFFF57F17), // warm mustard (spare, if backend ever returns 4+)
    Color(0xFF2E7D32), // forest green (spare)
  ];

  // Three distinct Ayat → Mexico Square paths (same coordinates previously
  // hardcoded in HomeScreen — now the single source of truth lives here).
  static const List<LatLng> _path1 = [
    LatLng(9.0248, 38.8680),
    LatLng(9.0195, 38.8005),
    LatLng(9.0142, 38.7808),
    LatLng(9.0103, 38.7617),
    LatLng(9.0100, 38.7450),
  ];
  static const List<LatLng> _path2 = [
    LatLng(9.0248, 38.8680),
    LatLng(8.9950, 38.8100),
    LatLng(8.9890, 38.7890),
    LatLng(9.0103, 38.7617),
    LatLng(9.0100, 38.7450),
  ];
  static const List<LatLng> _path3 = [
    LatLng(9.0248, 38.8680),
    LatLng(9.0400, 38.8300),
    LatLng(9.0350, 38.7650),
    LatLng(9.0320, 38.7520),
    LatLng(9.0100, 38.7450),
  ];

  /// The fail-safe dataset: used on initial load (fetchMockData) and
  /// whenever searchRoutes can't get usable data from the backend.
  static List<TransitRoute> _buildFallbackRoutes() => const [
    TransitRoute(
      id: 'ab-14',
      name: 'Anbessa Route 14',
      type: 'City Bus',
      etaMinutes: 7,
      fareAmount: 'ETB 4.00',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFFDE613B),
      stationNames: ['Ayat', 'CMC', 'Summit', 'Megenagna', 'Mexico Square'],
      coordinates: _path1,
    ),
    TransitRoute(
      id: 'sg-10',
      name: 'Sheger Route 10',
      type: 'Smart Bus',
      etaMinutes: 14,
      fareAmount: 'ETB 5.50',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.medium,
      routeColor: Color(0xFF00695C),
      stationNames: ['Ayat', 'Gofa', 'Kaliti', 'Akaki', 'Mexico Square'],
      coordinates: _path2,
    ),
    TransitRoute(
      id: 'cs-01',
      name: 'City Shuttle',
      type: 'Smart Bus',
      etaMinutes: 22,
      fareAmount: 'ETB 7.00',
      stationQueueLevel: CrowdLevel.high,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFF6A1B9A),
      stationNames: ['Ayat', 'Jemo', 'Lebu', 'Lideta', 'Mexico Square'],
      coordinates: _path3,
    ),
  ];

  static List<NearbyStation> _mockStations(double radius) {
    if (radius <= 500) {
      return const [
        NearbyStation(id: 's-ayat', name: 'Ayat Terminal', distanceMeters: 320),
        NearbyStation(id: 's-summit', name: 'Summit Stop', distanceMeters: 480),
      ];
    }
    return const [
      NearbyStation(id: 's-ayat', name: 'Ayat Terminal', distanceMeters: 320),
      NearbyStation(id: 's-summit', name: 'Summit Stop', distanceMeters: 480),
      NearbyStation(id: 's-lebu', name: 'Lebu Stop', distanceMeters: 620),
      NearbyStation(id: 's-qality', name: 'Qality Stop', distanceMeters: 710),
    ];
  }
}
