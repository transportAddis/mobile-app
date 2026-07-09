import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';

import 'package:mobile_app/models/nearby_station.dart';
import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/services/transit_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitProvider
// ─────────────────────────────────────────────────────────────────────────────

class TransitProvider extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────

  List<TransitRoute> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<NearbyStation> _nearbyStations = [];
  bool _isLoadingStations = false;
  String? _stationsError;

  /// Full city-wide station cache, used by SearchScreen's autocomplete.
  List<NearbyStation> _allStations = [];

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

  List<NearbyStation> get allStations => List.unmodifiable(_allStations);

  // ── Fetch: initial mock routes (unchanged) ──────────────────────────────────

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

  // ── Fetch: full station cache for autocomplete (NEW) ────────────────────────

  /// Populates [allStations] with every station in Addis Ababa, queried once
  /// on app open via a 100km radius from the city centre. Backs the
  /// SearchScreen autocomplete list.
  ///
  /// On failure, [_allStations] is simply left as-is (likely empty) —
  /// SearchScreen shows a loading/empty state rather than fake data.
  Future<void> fetchAllStations() async {
    try {
      final raw = await TransitApiService.instance.getNearbyStations(
        lat: 9.0248,
        lng: 38.7469,
        radius: 100000.0,
      );
      _allStations = raw
          .map((e) => NearbyStation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      debugPrint('[TransitProvider] fetchAllStations error: $e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  // ── Fetch: nearby stations (500 m → 750 m fallback, now LIVE) ──────────────

  /// Queries the backend for stations near [lat]/[lng]:
  ///   1. 500 m  →  if ≤ 2 results, retry at 750 m.
  ///   2. 750 m  →  if still empty, sets [stationsError].
  ///
  /// Each station's [NearbyStation.distanceMeters] is recomputed client-side
  /// via Haversine using [lat]/[lng] as the origin, since the backend's
  /// per-station payload isn't guaranteed to include a distance field.
  Future<void> fetchNearbyStations(double lat, double lng) async {
    _isLoadingStations = true;
    _stationsError = null;
    _nearbyStations = [];
    notifyListeners();

    try {
      var stations = await _fetchStationsAtRadius(lat, lng, 500);

      if (stations.length <= 2) {
        debugPrint('[TransitProvider] ≤2 stations at 500m — retrying at 750m.');
        stations = await _fetchStationsAtRadius(lat, lng, 750);
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

  Future<List<NearbyStation>> _fetchStationsAtRadius(
    double lat,
    double lng,
    double radius,
  ) async {
    final raw = await TransitApiService.instance.getNearbyStations(
      lat: lat,
      lng: lng,
      radius: radius,
    );

    return raw
        .map((e) => NearbyStation.fromJson(e as Map<String, dynamic>))
        .map(
          (station) => station.copyWith(
            distanceMeters: _haversineMeters(
              lat,
              lng,
              station.latitude,
              station.longitude,
            ),
          ),
        )
        .toList();
  }

  /// Great-circle distance between two coordinates, in metres.
  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);

  // ── Fetch: live route search (unchanged from previous task) ────────────────

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

  static List<TransitRoute> _parseRoutesFromApi(List<dynamic> rawPaths) {
    final routes = <TransitRoute>[];

    for (var i = 0; i < rawPaths.length; i++) {
      try {
        final segments = (rawPaths[i] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        if (segments.isEmpty) continue;

        final coordinates = <LatLng>[];
        final stopNames = <String>[];

        final firstOrigin =
            segments.first['originStation'] as Map<String, dynamic>;
        coordinates.add(_parseLatLng(firstOrigin));
        stopNames.add(_stationName(firstOrigin));

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
            type: (meta['type'] as String?) ?? 'Smart Bus',
            etaMinutes: _parseEta(meta['etaMinutes']),
            fareAmount: (meta['fareInfo'] as String?) ?? 'ETB —',
            stationQueueLevel: _parseCrowdLevel(meta['queueLevel']),
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

  // ── Mock fallback data (unchanged) ──────────────────────────────────────────

  static const List<Color> _kRoutePalette = [
    Color(0xFFDE613B),
    Color(0xFF00695C),
    Color(0xFF6A1B9A),
    Color(0xFFF57F17),
    Color(0xFF2E7D32),
  ];

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
}
