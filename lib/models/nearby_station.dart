// ─────────────────────────────────────────────────────────────────────────────
// NearbyStation
//
// A transit station returned by the radius-based nearby-station fetch.
// distanceMeters is the straight-line distance from the user's location;
// real Haversine calculation replaces the mock in Task 7.
// ─────────────────────────────────────────────────────────────────────────────

class NearbyStation {
  const NearbyStation({
    required this.id,
    required this.name,
    required this.distanceMeters,
  });

  final String id;
  final String name;

  /// Straight-line distance from the user's last known position.
  final double distanceMeters;

  // ── Display helper ─────────────────────────────────────────────────────────

  /// "320m" below 1 km, "1.2km" at or above.
  String get formattedDistance => distanceMeters < 1000
      ? '${distanceMeters.round()}m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)}km';

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
      'NearbyStation(id: $id, name: "$name", distance: '
      '$formattedDistance)';
}
