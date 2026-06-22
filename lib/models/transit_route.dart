// ─────────────────────────────────────────────────────────────────────────────
// CrowdLevel
//
// Represents live queue density at a station or occupancy inside a vehicle.
// Mapped directly to AppColors.crowdHigh / crowdMedium / crowdLow in the UI.
// ─────────────────────────────────────────────────────────────────────────────

enum CrowdLevel {
  low,
  medium,
  high;

  /// Parse from a JSON string value e.g. "low", "medium", "high".
  static CrowdLevel fromJson(String value) => CrowdLevel.values.byName(value);

  String toJson() => name;
}

// ─────────────────────────────────────────────────────────────────────────────
// TransitRoute
//
// A single transit service – either the Addis Ababa Light Rail (Train)
// or a Sheger Smart Bus route. Immutable value type; mutate via copyWith.
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
  }) : assert(
         type == 'Train' || type == 'Smart Bus',
         'type must be "Train" or "Smart Bus"',
       );

  /// Unique route identifier  e.g. "lr-ew-01", "sb-42"
  final String id;

  /// Human-readable name  e.g. "East-West Light Rail", "Sheger Route 42"
  final String name;

  /// "Train" or "Smart Bus"
  final String type;

  /// Estimated arrival at the user's current station, in minutes.
  final int etaMinutes;

  /// Display string for the fare  e.g. "ETB 2.00"
  final String fareAmount;

  /// How crowded the boarding queue at the station is right now.
  final CrowdLevel stationQueueLevel;

  /// How full the incoming vehicle is right now.
  final CrowdLevel vehicleOccupancyLevel;

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
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'eta_minutes': etaMinutes,
    'fare_amount': fareAmount,
    'station_queue_level': stationQueueLevel.toJson(),
    'vehicle_occupancy_level': vehicleOccupancyLevel.toJson(),
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
  }) => TransitRoute(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    etaMinutes: etaMinutes ?? this.etaMinutes,
    fareAmount: fareAmount ?? this.fareAmount,
    stationQueueLevel: stationQueueLevel ?? this.stationQueueLevel,
    vehicleOccupancyLevel: vehicleOccupancyLevel ?? this.vehicleOccupancyLevel,
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
      'eta: ${etaMinutes}min, queue: $stationQueueLevel, '
      'occupancy: $vehicleOccupancyLevel)';
}
