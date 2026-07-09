import 'package:mobile_app/models/transit_route.dart' show CrowdLevel;

// ─────────────────────────────────────────────────────────────────────────────
// NearbyStation
// ─────────────────────────────────────────────────────────────────────────────

class NearbyStation {
  const NearbyStation({
    required this.id,
    required this.name,
    this.distanceMeters = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.crowdLevel = 0,
  });

  final String id;
  final String name;

  /// Straight-line distance from the query point. NOT guaranteed by the
  /// backend response — TransitProvider recomputes this via Haversine once
  /// the caller's own lat/lng is known, so a default of 0.0 here is safe.
  final double distanceMeters;

  final double latitude;
  final double longitude;

  /// Raw backend crowd level: 0 = low, 1 = medium, 2 = high.
  final int crowdLevel;

  // ── Display helpers ─────────────────────────────────────────────────────────

  String get formattedDistance => distanceMeters < 1000
      ? '${distanceMeters.round()}m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)}km';

  /// Maps the raw int to our domain CrowdLevel enum. Anything outside 0-2
  /// clamps to the nearest valid level instead of throwing.
  CrowdLevel get crowdLevelEnum => switch (crowdLevel) {
    <= 0 => CrowdLevel.low,
    1 => CrowdLevel.medium,
    _ => CrowdLevel.high,
  };

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory NearbyStation.fromJson(Map<String, dynamic> json) => NearbyStation(
    id: json['id'] as String,
    name: json['name'] as String,
    // Backend sends coordinates as Strings.
    latitude: double.parse(json['latitude'] as String),
    longitude: double.parse(json['longitude'] as String),
    crowdLevel: json['crowdLevel'] as int? ?? 0,
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude.toString(),
    'longitude': longitude.toString(),
    'crowdLevel': crowdLevel,
    'distanceMeters': distanceMeters,
  };

  NearbyStation copyWith({
    String? id,
    String? name,
    double? distanceMeters,
    double? latitude,
    double? longitude,
    int? crowdLevel,
  }) => NearbyStation(
    id: id ?? this.id,
    name: name ?? this.name,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    crowdLevel: crowdLevel ?? this.crowdLevel,
  );

  // ── Equality ───────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NearbyStation &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NearbyStation(id: $id, name: "$name", distance: $formattedDistance)';
}
