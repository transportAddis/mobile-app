import 'package:flutter/foundation.dart';

import 'package:mobile_app/models/app_alert.dart';
import 'package:mobile_app/models/transit_route.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitProvider
//
// Single source of truth for all live transit data.
// Call fetchMockData() once from the root widget (e.g. via initState or
// a ProxyProvider) to hydrate the UI. In Task 5 this will be replaced
// by real HTTP calls via TransitService.
// ─────────────────────────────────────────────────────────────────────────────

class TransitProvider extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────

  List<TransitRoute> _routes = [];
  List<AppAlert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  // ── Public getters ─────────────────────────────────────────────────────────

  /// All available routes. Unmodifiable – mutate via provider methods only.
  List<TransitRoute> get routes => List.unmodifiable(_routes);

  /// Active service alerts, newest first.
  List<AppAlert> get alerts => List.unmodifiable(_alerts);

  bool get isLoading => _isLoading;

  /// Non-null when the last fetch failed. Reset to null on next fetch attempt.
  String? get error => _error;

  bool get hasError => _error != null;
  bool get hasRoutes => _routes.isNotEmpty;
  bool get hasAlerts => _alerts.isNotEmpty;

  /// Convenience: routes filtered by type.
  List<TransitRoute> get trainRoutes =>
      _routes.where((r) => r.type == 'Train').toList();

  List<TransitRoute> get busRoutes =>
      _routes.where((r) => r.type == 'Smart Bus').toList();

  // ── Data fetching ──────────────────────────────────────────────────────────

  /// Populates [routes] and [alerts] with realistic Addis Ababa dummy data.
  /// Simulates an 800ms network round-trip.
  ///
  /// Replace the body of this method with a real HTTP call in Task 5:
  ///   final data = await TransitService.instance.getRoutes();
  Future<void> fetchMockData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulated network latency
      await Future.delayed(const Duration(milliseconds: 800));

      _routes = _buildMockRoutes();
      _alerts = _buildMockAlerts();
    } catch (e, stack) {
      _error = 'Failed to load transit data. Please check your connection.';
      debugPrint('[TransitProvider] fetchMockData error: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mock data ──────────────────────────────────────────────────────────────

  static List<TransitRoute> _buildMockRoutes() => [
    // ── Addis Ababa Light Rail (ERC operated) ─────────────────────────────
    const TransitRoute(
      id: 'lr-ew-01',
      name: 'East-West Light Rail',
      type: 'Train',
      etaMinutes: 4,
      fareAmount: 'ETB 2.00',
      stationQueueLevel: CrowdLevel.high,
      vehicleOccupancyLevel: CrowdLevel.medium,
    ),
    const TransitRoute(
      id: 'lr-ns-01',
      name: 'North-South Light Rail',
      type: 'Train',
      etaMinutes: 11,
      fareAmount: 'ETB 2.00',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.high,
    ),

    // ── Sheger Smart Bus routes ────────────────────────────────────────────
    const TransitRoute(
      id: 'sb-42',
      name: 'Sheger Route 42',
      type: 'Smart Bus',
      etaMinutes: 7,
      fareAmount: 'ETB 5.50',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.low,
    ),
    const TransitRoute(
      id: 'sb-17',
      name: 'Sheger Route 17 – Piassa',
      type: 'Smart Bus',
      etaMinutes: 14,
      fareAmount: 'ETB 5.50',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.medium,
    ),
    const TransitRoute(
      id: 'sb-07',
      name: 'Sheger Route 07 – Mercato',
      type: 'Smart Bus',
      etaMinutes: 3,
      fareAmount: 'ETB 4.00',
      stationQueueLevel: CrowdLevel.high,
      vehicleOccupancyLevel: CrowdLevel.high,
    ),
    const TransitRoute(
      id: 'sb-31',
      name: 'Sheger Route 31 – Bole Express',
      type: 'Smart Bus',
      etaMinutes: 19,
      fareAmount: 'ETB 6.00',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.medium,
    ),
    const TransitRoute(
      id: 'sb-55',
      name: 'Sheger Route 55 – Kality Link',
      type: 'Smart Bus',
      etaMinutes: 23,
      fareAmount: 'ETB 7.00',
      stationQueueLevel: CrowdLevel.low,
      vehicleOccupancyLevel: CrowdLevel.low,
    ),
    const TransitRoute(
      id: 'sb-12',
      name: 'Sheger Route 12 – CMC Road',
      type: 'Smart Bus',
      etaMinutes: 9,
      fareAmount: 'ETB 5.00',
      stationQueueLevel: CrowdLevel.medium,
      vehicleOccupancyLevel: CrowdLevel.low,
    ),
  ];

  static List<AppAlert> _buildMockAlerts() {
    final now = DateTime.now();
    return [
      AppAlert(
        id: 'alert-001',
        title: 'AU Summit Traffic Alert',
        description:
            'Heavy vehicle restrictions are in effect along Bole Road due to '
            'the African Union summit. Expect 15–25 min delays on Sheger '
            'Routes 31 and 17.',
        severity: 'warning',
        timestamp: now.subtract(const Duration(minutes: 22)),
      ),
      AppAlert(
        id: 'alert-002',
        title: 'Meskel Square Station: Platform Works',
        description:
            'Platform 2 at Meskel Square is undergoing scheduled maintenance. '
            'East-West Line passengers board from Platform 1 only until 18:00.',
        severity: 'info',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      AppAlert(
        id: 'alert-003',
        title: 'North-South Line: Reduced Frequency',
        description:
            'The North-South Light Rail is running at 20-minute intervals '
            'until 14:00 due to a track inspection. Normal 10-minute frequency '
            'resumes this afternoon.',
        severity: 'warning',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      AppAlert(
        id: 'alert-004',
        title: 'Route 42 Extension Now Live',
        description:
            'Sheger Route 42 now serves Jemo and Lebu with 6 additional stops. '
            'Updated timetables are available at all served stations.',
        severity: 'info',
        timestamp: now.subtract(const Duration(hours: 18)),
      ),
      AppAlert(
        id: 'alert-005',
        title: 'Lideta Station: Lift Out of Service',
        description:
            'The passenger lift at Lideta station is temporarily out of '
            'service. Staff are available to assist passengers with mobility needs.',
        severity: 'info',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
