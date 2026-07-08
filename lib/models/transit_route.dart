import 'package:flutter/material.dart' show Color;

enum CrowdLevel {
  low,
  medium,
  high;

  static CrowdLevel fromJson(String value) => CrowdLevel.values.byName(value);
  String toJson() => name;
}

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
    this.stationNames = const <String>[],
  });

  final String id;
  final String name;
  final String type;
  final int etaMinutes;
  final String fareAmount;
  final CrowdLevel stationQueueLevel;
  final CrowdLevel vehicleOccupancyLevel;
  final Color routeColor;
  final List<String> stationNames;

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
    stationNames: json['station_names'] != null
        ? List<String>.from(json['station_names'] as List)
        : const <String>[],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'eta_minutes': etaMinutes,
    'fare_amount': fareAmount,
    'station_queue_level': stationQueueLevel.toJson(),
    'vehicle_occupancy_level': vehicleOccupancyLevel.toJson(),
    // FIX: .value is deprecated — use .toARGB32() for an explicit 32-bit conversion.
    'route_color_value': routeColor.toARGB32(),
    'station_names': stationNames,
  };

  TransitRoute copyWith({
    String? id,
    String? name,
    String? type,
    int? etaMinutes,
    String? fareAmount,
    CrowdLevel? stationQueueLevel,
    CrowdLevel? vehicleOccupancyLevel,
    Color? routeColor,
    List<String>? stationNames,
  }) => TransitRoute(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    etaMinutes: etaMinutes ?? this.etaMinutes,
    fareAmount: fareAmount ?? this.fareAmount,
    stationQueueLevel: stationQueueLevel ?? this.stationQueueLevel,
    vehicleOccupancyLevel: vehicleOccupancyLevel ?? this.vehicleOccupancyLevel,
    routeColor: routeColor ?? this.routeColor,
    stationNames: stationNames ?? this.stationNames,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransitRoute &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;
}
