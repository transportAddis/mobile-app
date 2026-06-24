import 'package:flutter/material.dart' show Color;

// ─────────────────────────────────────────────────────────────────────────────
// CrowdLevel
// ─────────────────────────────────────────────────────────────────────────────

enum CrowdLevel {
  low,
  medium,
  high;

  static CrowdLevel fromJson(String value) => CrowdLevel.values.byName(value);
  String toJson() => name;
}

// ─────────────────────────────────────────────────────────────────────────────
// TransitRoute
//
// Immutable value type. routeColor is used by:
//   • The Polyline drawn on FlutterMap (Task 6)
//   • The midpoint pill badge background (Task 6)
//   • The RouteCard accent stripe (future)
// ─────────────────────────────────────────────────────────────────────────────

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.name,
    required this.type,
    required this.etaMinutes,
    required this.fareAmount,
    required this.stationQueueLevel,
    required this.vehicleOccupancyLevel,
    required this.routeColor,
  }) : assert(
         type == 'Train' || type == 'Smart Bus',
         'type must be "Train" or "Smart Bus"',
       );

  final String id;
  final String name;

  /// "Train" or "Smart Bus"
  final String type;

  final int etaMinutes;
  final String fareAmount;
  final CrowdLevel stationQueueLevel;
  final CrowdLevel vehicleOccupancyLevel;

  /// Distinct per-route colour for map polylines and badges.
  /// Assigned in TransitProvider mock data; backend will supply this in Task 7.
  final Color routeColor;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory TransitRoute.fromJson(Map<String, dynamic> json) => TransitRoute(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    etaMinutes: json['eta_minutes'] as int,
    fareAmount: json['fare_amount'] as String,
    stationQueueLevel: CrowdLevel.fromJson(
      json['station_queue_level'] as String,
    ),
    vehicleOccupancyLevel: CrowdLevel.fromJson(
      json['vehicle_occupancy_level'] as String,
    ),
    routeColor: Color(json['route_color_value'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'eta_minutes': etaMinutes,
    'fare_amount': fareAmount,
    'station_queue_level': stationQueueLevel.toJson(),
    'vehicle_occupancy_level': vehicleOccupancyLevel.toJson(),
    'route_color_value': routeColor.toARGB32(),
  };

  // ── copyWith ───────────────────────────────────────────────────────────────

  TransitRoute copyWith({
    String? id,
    String? name,
    String? type,
    int? etaMinutes,
    String? fareAmount,
    CrowdLevel? stationQueueLevel,
    CrowdLevel? vehicleOccupancyLevel,
    Color? routeColor,
  }) => TransitRoute(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    etaMinutes: etaMinutes ?? this.etaMinutes,
    fareAmount: fareAmount ?? this.fareAmount,
    stationQueueLevel: stationQueueLevel ?? this.stationQueueLevel,
    vehicleOccupancyLevel: vehicleOccupancyLevel ?? this.vehicleOccupancyLevel,
    routeColor: routeColor ?? this.routeColor,
  );

  // ── Equality & debug ───────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransitRoute &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TransitRoute(id: $id, name: "$name", type: $type, '
      'eta: ${etaMinutes}min)';
}
