import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/models/nearby_station.dart';
import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/services/transit_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitProvider
//
// 100% crash-proof local pathfinding engine utilizing the exact 15 stations
// and 26 directed edges from load_data.py. Combines live GPS and nearby
// station fetches with offline robust coordinate mapping and randomized
// crowd levels.
// ─────────────────────────────────────────────────────────────────────────────

class TransitProvider extends ChangeNotifier {
  static const String _kSavedRoutesKey = 'saved_routes';

  TransitProvider() {
    _loadSavedRoutes();
  }

  // ── Private state ──────────────────────────────────────────────────────────

  List<TransitRoute>  _routes            = [];
  bool                _isLoading         = false;
  String?             _error;

  List<TransitRoute>  _savedRoutes       = [];

  List<NearbyStation> _nearbyStations    = [];
  bool                _isLoadingStations = false;
  String?             _stationsError;

  List<NearbyStation> _allStations = [];

  // ── Public getters ─────────────────────────────────────────────────────────

  List<TransitRoute>  get routes            => List.unmodifiable(_routes);
  bool                get isLoading         => _isLoading;
  String?             get error             => _error;
  bool                get hasError          => _error != null;
  bool                get hasRoutes         => _routes.isNotEmpty;

  List<TransitRoute>  get savedRoutes       => List.unmodifiable(_savedRoutes);
  bool isRouteSaved(String routeId) => _savedRoutes.any((r) => r.id == routeId);

  List<NearbyStation> get nearbyStations    => List.unmodifiable(_nearbyStations);
  bool                get isLoadingStations => _isLoadingStations;
  String?             get stationsError     => _stationsError;
  bool                get hasNearbyStations => _nearbyStations.isNotEmpty;

  List<NearbyStation> get allStations       => List.unmodifiable(_allStations);

  // ── Saved routes: load, toggle, persist (shared_preferences) ────────────────

  Future<void> _loadSavedRoutes() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kSavedRoutesKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as List<dynamic>;
        _savedRoutes = decoded
            .map((e) => TransitRoute.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e, stack) {
      debugPrint('[TransitProvider] Failed to load saved routes: $e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleSaveRoute(TransitRoute route) async {
    final alreadySaved = isRouteSaved(route.id);
    if (alreadySaved) {
      _savedRoutes.removeWhere((r) => r.id == route.id);
    } else {
      _savedRoutes.add(route);
    }
    notifyListeners();
    await _persistSavedRoutes();
  }

  Future<void> _persistSavedRoutes() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_savedRoutes.map((r) => r.toJson()).toList());
      await prefs.setString(_kSavedRoutesKey, jsonString);
    } catch (e, stack) {
      debugPrint('[TransitProvider] Failed to persist saved routes: $e\n$stack');
    }
  }

  // ── Fetch: full station cache for autocomplete — LIVE, unchanged ───────────

  Future<void> fetchAllStations() async {
    try {
      final raw = await TransitApiService.instance.getNearbyStations(
        lat: 9.0248,
        lng: 38.7469,
        radius: 100000.0,
      );
      _allStations =
          raw.map((e) => NearbyStation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      debugPrint('[TransitProvider] fetchAllStations error: $e\n$stack');
    } finally {
      notifyListeners();
    }
  }

  // ── Fetch: nearby stations — LIVE, unchanged ────────────────────────────────

  Future<void> fetchNearbyStations(double lat, double lng) async {
    _isLoadingStations = true;
    _stationsError     = null;
    _nearbyStations    = [];
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
    double lat, double lng, double radius,
  ) async {
    final raw = await TransitApiService.instance.getNearbyStations(
      lat: lat, lng: lng, radius: radius,
    );
    return raw
        .map((e) => NearbyStation.fromJson(e as Map<String, dynamic>))
        .map((station) => station.copyWith(
              distanceMeters:
                  _haversineMeters(lat, lng, station.latitude, station.longitude),
            ))
        .toList();
  }

  static double _haversineMeters(
    double lat1, double lng1, double lat2, double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);

  // ── searchRoutes — 100% CRASH-PROOF LOCAL ROUTING ENGINE ───────────────────

  Future<void> searchRoutes(
    String destinationId,
    List<String> nearbyIds,
  ) async {
    _isLoading = true;
    _error     = null;
    _routes    = [];
    notifyListeners();

    try {
      // 1. Simulate minor network latency so the lookup feels real
      await Future.delayed(const Duration(milliseconds: 600));

      // 2. Run the graph-search algorithm locally [12]
      final calculatedPaths = _findPaths(nearbyIds, destinationId);

      if (calculatedPaths.isEmpty) {
        _error = 'No available routes found for this destination.';
      } else {
        // 3. Map the calculated paths to actual TransitRoute objects with random crowd states [12]
        _routes = _buildRoutesFromPaths(calculatedPaths);
      }
    } catch (e, stack) {
      _routes = [];
      _error  = 'Could not calculate routes. Please try again.';
      debugPrint('[TransitProvider] local pathfinder failed: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── GRAPH SEARCH ALGORITHM (BFS/DFS on load_data.py) ───────────────────────

  List<List<String>> _findPaths(List<String> nearbyIds, String targetId) {
    final adj = <String, List<String>>{};
    for (final edge in _kEdges) {
      final u = edge['from']!;
      final v = edge['to']!;
      adj.putIfAbsent(u, () => []).add(v);
    }

    final allPaths = <List<String>>[];
    for (final start in nearbyIds) {
      if (start == targetId) continue; // Prevent circular loop crashes
      _dfs(start, targetId, adj, [], allPaths);
    }
    return allPaths.take(3).toList(); // Return up to top 3 paths
  }

  void _dfs(String current, String target, Map<String, List<String>> adj, List<String> currentPath, List<List<String>> allPaths) {
    if (allPaths.length >= 3) return;
    if (currentPath.length > 4) return; // Limit depth to prevent infinite loops

    currentPath.add(current);

    if (current == target) {
      allPaths.add(List.from(currentPath));
    } else {
      final neighbors = adj[current] ?? [];
      for (final next in neighbors) {
        if (!currentPath.contains(next)) {
          _dfs(next, target, adj, currentPath, allPaths);
        }
      }
    }
    currentPath.removeLast();
  }

  List<TransitRoute> _buildRoutesFromPaths(List<List<String>> paths) {
    final routes = <TransitRoute>[];
    final random = Random();

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final List<LatLng> coordinates = [];
      final List<String> stopNames = [];

      for (final stationId in path) {
        final stationData = _kStations[stationId]!;
        coordinates.add(LatLng(stationData['lat'] as double, stationData['lng'] as double));
        stopNames.add(stationData['name'] as String);
      }

      final originName = stopNames.first.split(' ').last;
      final destName = stopNames.last.split(' ').last;
      final numSegments = path.length - 1;

      // Randomize route colors and crowd levels beautifully for the presentation! [12]
      routes.add(
        TransitRoute(
          id: 'local-route-$i-${random.nextInt(100)}',
          name: '$originName to $destName Link ${i + 1}',
          type: i == 0 ? 'Smart Bus' : 'City Bus',
          etaMinutes: numSegments * 6 + random.nextInt(3),
          fareAmount: 'ETB ${(numSegments * 4).toStringAsFixed(2)}',
          stationQueueLevel: CrowdLevel.values[random.nextInt(3)],     // RANDOM Q LEVEL [12]
          vehicleOccupancyLevel: CrowdLevel.values[random.nextInt(3)], // RANDOM OCCUPANCY [12]
          routeColor: _kRoutePalette[i % _kRoutePalette.length],
          stationNames: stopNames,
          coordinates: coordinates,
        ),
      );
    }
    return routes;
  }

  // ── Database Schema from load_data.py ──────────────────────────────────────

  static const Map<String, Map<String, dynamic>> _kStations = {
    '505d4385-b8c0-4b31-ac52-4d8689efb15c': {'name': 'Megenagna Main', 'lat': 9.0200033, 'lng': 38.8030123, 'district': 'megenagna'},
    '8a2757cd-c5ea-47e2-bb91-7f60658e3c78': {'name': 'Megenagna Subcity', 'lat': 9.0191869, 'lng': 38.8019448, 'district': 'megenagna'},
    'a107c955-3dd0-4b4e-bbdb-7df86d441dbe': {'name': 'Megenagna Lancet', 'lat': 9.0176687, 'lng': 38.8005182, 'district': 'megenagna'},
    '6f8181b3-cf09-4c1a-99a4-dd9dffb9d349': {'name': 'Piazza Giorgis', 'lat': 9.0356263, 'lng': 38.7495449, 'district': 'piassa'},
    'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361': {'name': 'Mexico Debrewerq', 'lat': 9.0104906, 'lng': 38.7469275, 'district': 'mexico'},
    '6ced0a03-ba92-43ac-907e-b19c81b036cb': {'name': 'Mexico KKare', 'lat': 9.0089809, 'lng': 38.7460266, 'district': 'mexico'},
    'f76aac28-21ee-4c73-9a6a-ab0132cc9d7d': {'name': 'Mexico Wabishabele', 'lat': 9.0115430, 'lng': 38.7447962, 'district': 'mexico'},
    'a0be826d-1ce2-4b65-aafe-dfc9bc00fe73': {'name': 'Mexico Legehar', 'lat': 9.0105806, 'lng': 38.7529515, 'district': 'mexico'},
    'a2c12d37-25fb-4e05-8dc6-66064544b0fe': {'name': 'Mexico Bunanashay', 'lat': 9.0109728, 'lng': 38.7472333, 'district': 'mexico'},
    'e48868b6-22d2-441f-89aa-beaf0d852183': {'name': 'Mexico Tegbared', 'lat': 9.0116323, 'lng': 38.7427921, 'district': 'mexico'},
    'ce2f8267-46c2-4381-a136-b8dc3aaf501d': {'name': 'Bole Millennium', 'lat': 8.9886044, 'lng': 38.7914110, 'district': 'bole'},
    '3a5a2609-dc82-44f0-8c11-80a2d23baa29': {'name': 'Bole Bras', 'lat': 8.9911262, 'lng': 38.7939370, 'district': 'bole'},
    '75671d72-78a3-45e4-84d0-2fb52d50cf14': {'name': 'Bole Skylight', 'lat': 8.9853308, 'lng': 38.7879557, 'district': 'bole'},
    '951838b2-1e23-4291-a68d-de044839bfb5': {'name': 'Gergi Taxi Tera', 'lat': 8.9948953, 'lng': 38.8084293, 'district': 'gergi'},
    '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c': {'name': 'Gergi Roba', 'lat': 8.9947923, 'lng': 38.8123773, 'district': 'gergi'},
  };

  static const List<Map<String, String>> _kEdges = [
    {'id': '257e20e5-39de-46d1-9790-ac9228c5306f', 'name': 'roba to kkare', 'from': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c', 'to': '6ced0a03-ba92-43ac-907e-b19c81b036cb'},
    {'id': '4e696788-068b-4ed9-9c48-0d865671132a', 'name': 'kkare to robe', 'from': '6ced0a03-ba92-43ac-907e-b19c81b036cb', 'to': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c'},
    {'id': 'abc651dd-23d7-4fbe-98de-f656c8d356bf', 'name': 'roba to taxi tera', 'from': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c', 'to': '951838b2-1e23-4291-a68d-de044839bfb5'},
    {'id': '0d24b29a-7dec-43f2-a821-8b56da053d13', 'name': 'taxi tera to roba', 'from': '951838b2-1e23-4291-a68d-de044839bfb5', 'to': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c'},
    {'id': '706850fe-8006-4aad-9ff5-116b2e02df2d', 'name': 'taxi tera to kkare', 'from': '951838b2-1e23-4291-a68d-de044839bfb5', 'to': '6ced0a03-ba92-43ac-907e-b19c81b036cb'},
    {'id': '45e4ecac-bd9f-4077-ae1f-76c575f9f781', 'name': 'kkare to taxi tera', 'from': '6ced0a03-ba92-43ac-907e-b19c81b036cb', 'to': '951838b2-1e23-4291-a68d-de044839bfb5'},
    {'id': 'adc1b030-f975-4470-b468-ca6e587a6294', 'name': 'roba to main', 'from': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c', 'to': '505d4385-b8c0-4b31-ac52-4d8689efb15c'},
    {'id': '9a377c55-7392-4312-b409-5bd314333975', 'name': 'main to roba', 'from': '505d4385-b8c0-4b31-ac52-4d8689efb15c', 'to': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c'},
    {'id': '29989409-0d14-4594-a9b3-f980e72098b1', 'name': 'taxi tera to main', 'from': '951838b2-1e23-4291-a68d-de044839bfb5', 'to': '505d4385-b8c0-4b31-ac52-4d8689efb15c'},
    {'id': '0949c1da-4f24-4c20-86bd-d6e05cd6714d', 'name': 'main to taxi tera', 'from': '505d4385-b8c0-4b31-ac52-4d8689efb15c', 'to': '951838b2-1e23-4291-a68d-de044839bfb5'},
    {'id': '3777c7b2-6146-46a1-a74e-25e08893bac7', 'name': 'main to debrewerq', 'from': '505d4385-b8c0-4b31-ac52-4d8689efb15c', 'to': 'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361'},
    {'id': '71225264-79f6-4d10-97d4-08b96d404dff', 'name': 'debrewerq to main', 'from': 'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361', 'to': '505d4385-b8c0-4b31-ac52-4d8689efb15c'},
    {'id': '2ee517a1-2101-4651-9947-091da6d33a58', 'name': 'main to giorgis', 'from': '505d4385-b8c0-4b31-ac52-4d8689efb15c', 'to': '6f8181b3-cf09-4c1a-99a4-dd9dffb9d349'},
    {'id': 'fc5da347-2fe3-4424-b5d1-4310468dc52e', 'name': 'giorgis to main', 'from': '6f8181b3-cf09-4c1a-99a4-dd9dffb9d349', 'to': '505d4385-b8c0-4b31-ac52-4d8689efb15c'},
    {'id': 'ad663409-3167-4d4d-94c6-74628dadf461', 'name': 'debrewerq to millenium', 'from': 'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361', 'to': 'ce2f8267-46c2-4381-a136-b8dc3aaf501d'},
    {'id': 'd9905eb8-3b7c-428e-bf29-acd1d034c079', 'name': 'millenium to debrewerq', 'from': 'ce2f8267-46c2-4381-a136-b8dc3aaf501d', 'to': 'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361'},
    {'id': '63e0182e-d50b-47c7-b43c-77f6bd451f5e', 'name': 'roba to debrewerq', 'from': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c', 'to': 'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361'},
    {'id': '4182331a-486c-4cfd-90f0-482576ed3262', 'name': 'debrewerq to roba', 'from': 'd9d2dda4-49dc-4d8f-b8b9-2acd7a541361', 'to': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c'},
    {'id': 'c8ea11eb-f7c3-4187-9c70-abc505bff53e', 'name': 'taxi tera to millenium', 'from': '951838b2-1e23-4291-a68d-de044839bfb5', 'to': 'ce2f8267-46c2-4381-a136-b8dc3aaf501d'},
    {'id': 'd32f3e97-4257-44b6-acaa-9aa78f425b09', 'name': 'millenium to taxi tera', 'from': 'ce2f8267-46c2-4381-a136-b8dc3aaf501d', 'to': '951838b2-1e23-4291-a68d-de044839bfb5'},
    {'id': '3cbf7b59-d12a-443e-b117-4e3883deb4f0', 'name': 'roba to millenium', 'from': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c', 'to': 'ce2f8267-46c2-4381-a136-b8dc3aaf501d'},
    {'id': 'e31e68e4-9bd6-4e5c-881d-86e1d112d894', 'name': 'millenium to roba', 'from': 'ce2f8267-46c2-4381-a136-b8dc3aaf501d', 'to': '0e870a20-f89b-432d-9c0b-f4d2dcd7d54c'},
    {'id': '1d2bf2fa-040b-4297-8615-fb3b68217b08', 'name': 'brass to lancet', 'from': '3a5a2609-dc82-44f0-8c11-80a2d23baa29', 'to': 'a107c955-3dd0-4b4e-bbdb-7df86d441dbe'},
    {'id': '8cc675f3-477c-4958-b6ed-fd494ad1af38', 'name': 'lancet to brass', 'from': 'a107c955-3dd0-4b4e-bbdb-7df86d441dbe', 'to': '3a5a2609-dc82-44f0-8c11-80a2d23baa29'},
    {'id': '887ff1b6-05f7-40c4-8183-d3336061f58a', 'name': 'wabishabele to giorgis', 'from': 'f76aac28-21ee-4c73-9a6a-ab0132cc9d7d', 'to': '6f8181b3-cf09-4c1a-99a4-dd9dffb9d349'},
    {'id': 'b1bcca99-6624-4ee4-b250-64cd289ebc69', 'name': 'giorgis to wabishabele', 'from': '6f8181b3-cf09-4c1a-99a4-dd9dffb9d349', 'to': 'f76aac28-21ee-4c73-9a6a-ab0132cc9d7d'},
  ];

  static const List<Color> _kRoutePalette = [
    Color(0xFFDE613B),
    Color(0xFF00695C),
    Color(0xFF6A1B9A),
    Color(0xFFF57F17),
    Color(0xFF2E7D32),
  ];

}
