import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';

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
    this.coordinates = const <LatLng>[],
  });

  final String id;
  final String name;
  final String type;
  final int etaMinutes;
  final String fareAmount;
  final CrowdLevel stationQueueLevel;
  final CrowdLevel vehicleOccupancyLevel;
  final Color routeColor;

  /// Ordered stop names — feeds the RouteCard station timeline.
  final List<String> stationNames;

  /// Ordered map coordinates for this route's polyline. Populated either by
  /// [TransitProvider._parseRoutesFromApi] (live backend) or by the mock
  /// fallback paths when the API is unreachable or returns no data.
  final List<LatLng> coordinates;

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
    coordinates: json['coordinates'] != null
        ? (json['coordinates'] as List)
              .map(
                (e) => LatLng(
                  (e['lat'] as num).toDouble(),
                  (e['lng'] as num).toDouble(),
                ),
              )
              .toList()
        : const <LatLng>[],
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
    'station_names': stationNames,
    'coordinates': coordinates
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
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
    List<LatLng>? coordinates,
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
    coordinates: coordinates ?? this.coordinates,
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
