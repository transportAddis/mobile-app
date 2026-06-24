import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';

import 'package:mobile_app/models/nearby_station.dart';
import 'package:mobile_app/models/transit_route.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitProvider
//
// Single source of truth for all live transit data.
// AppAlert has been removed from scope (architecture pivot).
//
// Task 6 will add:
//   • selectedRouteIndex      — which polyline the user highlighted
//   • A method to receive route LatLng data from the backend and
//     expose it so HomeScreen can build color-coded Polyline objects.
// ─────────────────────────────────────────────────────────────────────────────

class TransitProvider extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────

  List<TransitRoute> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<NearbyStation> _nearbyStations = [];
  bool _isLoadingStations = false;
  String? _stationsError;

  // ── Public getters: routes ─────────────────────────────────────────────────

  List<TransitRoute> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasRoutes => _routes.isNotEmpty;

  List<TransitRoute> get trainRoutes =>
      _routes.where((r) => r.type == 'Train').toList();
  List<TransitRoute> get busRoutes =>
      _routes.where((r) => r.type == 'Smart Bus').toList();

  // ── Public getters: nearby stations ───────────────────────────────────────

  List<NearbyStation> get nearbyStations => List.unmodifiable(_nearbyStations);
  bool get isLoadingStations => _isLoadingStations;
  String? get stationsError => _stationsError;
  bool get hasStationsError => _stationsError != null;
  bool get hasNearbyStations => _nearbyStations.isNotEmpty;

  // ── Fetch: routes ──────────────────────────────────────────────────────────

  /// Populates [routes] with mock data.
  /// Task 7: replace body with TransitService.instance.getRoutes().
  Future<void> fetchMockData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _routes = _buildMockRoutes();
    } catch (e, stack) {
      _error = 'Failed to load transit data. Please check your connection.';
      debugPrint('[TransitProvider] fetchMockData error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch: nearby stations (500 m → 750 m fallback) ───────────────────────

  /// Fetches stations near [lat]/[lng]:
  ///   1. 500m  →  if ≤ 2 results, retry at 750m.
  ///   2. 750m  →  if still empty, sets [stationsError].
  ///
  /// Real Haversine + HTTP replaces this in Task 7.
  Future<void> fetchNearbyStations(double lat, double lng) async {
    _isLoadingStations = true;
    _stationsError = null;
    _nearbyStations = [];
    notifyListeners();

    try {
      // Step 1: 500 m
      await Future.delayed(const Duration(milliseconds: 600));
      var stations = _mockStationsWithinRadius(radiusMeters: 500);
      debugPrint('[TransitProvider] 500 m → ${stations.length} station(s).');

      // Step 2: automatic retry
      if (stations.length <= 2) {
        debugPrint('[TransitProvider] ≤2 results — retrying at 750 m.');
        await Future.delayed(const Duration(milliseconds: 400));
        stations = _mockStationsWithinRadius(radiusMeters: 750);
        debugPrint('[TransitProvider] 750 m → ${stations.length} station(s).');
      }

      if (stations.isEmpty) {
        _stationsError = 'No stations found near you.';
      } else {
        _nearbyStations = stations;
      }
    } catch (e, stack) {
      _stationsError = 'Could not load nearby stations. Please try again.';
      debugPrint('[TransitProvider] fetchNearbyStations error: $e\n$stack');
    } finally {
      _isLoadingStations = false;
      notifyListeners();
    }
  }

  // ── Mock helpers ──────────────────────────────────────────────────────────

  static List<NearbyStation> _mockStationsWithinRadius({
    required double radiusMeters,
  }) {
    if (radiusMeters <= 500) {
      return const [
        NearbyStation(id: 's-ayat', name: 'Ayat Station', distanceMeters: 320),
        NearbyStation(
          id: 's-summit',
          name: 'Summit Station',
          distanceMeters: 480,
        ),
      ];
    }
    return const [
      NearbyStation(id: 's-ayat', name: 'Ayat Station', distanceMeters: 320),
      NearbyStation(
        id: 's-summit',
        name: 'Summit Station',
        distanceMeters: 480,
      ),
      NearbyStation(id: 's-lebu', name: 'Lebu Station', distanceMeters: 620),
      NearbyStation(
        id: 's-qality',
        name: 'Qality Station',
        distanceMeters: 710,
      ),
    ];
  }

  static List<TransitRoute> _buildMockRoutes() => [
    // ── Light Rail — blue family ───────────────────────────────────────────
    const TransitRoute(
      id: 'lr-ew-01',
      name: 'East-West Light Rail',
      type: 'Train',
      etaMinutes: 4,
      fareAmount: 'ETB 2.00',
      stationQueueLevel: CrowdLevel.high,
      vehicleOccupancyLevel: CrowdLevel.medium,
      routeColor: Color(0xFF1565C0), // deep blue
    ),
    const TransitRoute(
      id: 'lr-ns-01',
      name: 'North-South Light Rail',
      type: 'Train',
      etaMinutes: 11,
      fareAmount: 'ETB 2.00',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.high,
      routeColor: Color(0xFF0277BD), // steel blue
    ),

    // ── Sheger Smart Bus — each a unique accent ────────────────────────────
    const TransitRoute(
      id: 'sb-42',
      name: 'Sheger Route 42',
      type: 'Smart Bus',
      etaMinutes: 7,
      fareAmount: 'ETB 5.50',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFFDE613B), // primary terracotta (app brand)
    ),
    const TransitRoute(
      id: 'sb-17',
      name: 'Sheger Route 17 – Piassa',
      type: 'Smart Bus',
      etaMinutes: 14,
      fareAmount: 'ETB 5.50',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.medium,
      routeColor: Color(0xFF00695C), // deep teal
    ),
    const TransitRoute(
      id: 'sb-07',
      name: 'Sheger Route 07 – Mercato',
      type: 'Smart Bus',
      etaMinutes: 3,
      fareAmount: 'ETB 4.00',
      stationQueueLevel: CrowdLevel.high,
      vehicleOccupancyLevel: CrowdLevel.high,
      routeColor: Color(0xFFF57F17), // warm mustard
    ),
    const TransitRoute(
      id: 'sb-31',
      name: 'Sheger Route 31 – Bole Express',
      type: 'Smart Bus',
      etaMinutes: 19,
      fareAmount: 'ETB 6.00',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.medium,
      routeColor: Color(0xFF6A1B9A), // deep purple
    ),
    const TransitRoute(
      id: 'sb-55',
      name: 'Sheger Route 55 – Kality Link',
      type: 'Smart Bus',
      etaMinutes: 23,
      fareAmount: 'ETB 7.00',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFF2E7D32), // forest green
    ),
    const TransitRoute(
      id: 'sb-12',
      name: 'Sheger Route 12 – CMC Road',
      type: 'Smart Bus',
      etaMinutes: 9,
      fareAmount: 'ETB 5.00',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFFC62828), // deep red
    ),
  ];
}
