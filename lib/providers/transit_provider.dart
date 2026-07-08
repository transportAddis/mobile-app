import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import 'package:mobile_app/models/nearby_station.dart';
import 'package:mobile_app/models/transit_route.dart';

class TransitProvider extends ChangeNotifier {
  List<TransitRoute> _routes = [];
  bool _isLoading = false;
  String? _error;
  List<NearbyStation> _nearbyStations = [];
  bool _isLoadingStations = false;
  String? _stationsError;

  List<TransitRoute> get routes => List.unmodifiable(_routes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasRoutes => _routes.isNotEmpty;
  List<NearbyStation> get nearbyStations => List.unmodifiable(_nearbyStations);
  bool get isLoadingStations => _isLoadingStations;
  String? get stationsError => _stationsError;
  bool get hasNearbyStations => _nearbyStations.isNotEmpty;

  Future<void> fetchMockData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _routes = _buildMockRoutes();
    } catch (e, s) {
      _error = 'Failed to load data.';
      debugPrint('[TransitProvider] $e\n$s');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyStations(double lat, double lng) async {
    _isLoadingStations = true;
    _stationsError = null;
    _nearbyStations = [];
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      var s = _mockStations(500);
      if (s.length <= 2) {
        await Future.delayed(const Duration(milliseconds: 400));
        s = _mockStations(750);
      }
      // FIX: braces added around both branches (curly_braces_in_flow_control_structures)
      if (s.isEmpty) {
        _stationsError = 'No stations found near you.';
      } else {
        _nearbyStations = s;
      }
    } catch (e, stack) {
      _stationsError = 'Could not load nearby stations.';
      debugPrint('[TransitProvider] $e\n$stack');
    } finally {
      _isLoadingStations = false;
      notifyListeners();
    }
  }

  static List<TransitRoute> _buildMockRoutes() => [
    const TransitRoute(
      id: 'ab-14',
      name: 'Anbessa Route 14',
      type: 'City Bus',
      etaMinutes: 7,
      fareAmount: 'ETB 4.00',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFFDE613B),
      stationNames: ['Ayat', 'CMC', 'Summit', 'Megenagna', 'Mexico Square'],
    ),
    const TransitRoute(
      id: 'sg-10',
      name: 'Sheger Route 10',
      type: 'Smart Bus',
      etaMinutes: 14,
      fareAmount: 'ETB 5.50',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.medium,
      routeColor: Color(0xFF00695C),
      stationNames: ['Ayat', 'Gofa', 'Kaliti', 'Akaki', 'Mexico Square'],
    ),
    const TransitRoute(
      id: 'cs-01',
      name: 'City Shuttle',
      type: 'Smart Bus',
      etaMinutes: 22,
      fareAmount: 'ETB 7.00',
      stationQueueLevel: CrowdLevel.high,
      vehicleOccupancyLevel: CrowdLevel.low,
      routeColor: Color(0xFF6A1B9A),
      stationNames: ['Ayat', 'Jemo', 'Lebu', 'Lideta', 'Mexico Square'],
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
