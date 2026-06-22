// ─────────────────────────────────────────────────────────────────────────────
// AppAlert
//
// A system notification surfaced in the transit alerts banner.
// severity is constrained to "warning" | "info" per the design spec.
// Immutable value type; mutate via copyWith.
// ─────────────────────────────────────────────────────────────────────────────

class AppAlert {
  const AppAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
  }) : assert(
         severity == 'warning' || severity == 'info',
         'severity must be "warning" or "info"',
       );

  /// Unique alert identifier  e.g. "alert-001"
  final String id;

  /// Short headline  e.g. "AU Summit Traffic Alert"
  final String title;

  /// Full detail text shown in the expanded alert card.
  final String description;

  /// "warning" (amber, service disruption) or "info" (blue, general notice).
  final String severity;

  /// When the alert was issued, in local device time.
  final DateTime timestamp;

  // ── Derived helpers ────────────────────────────────────────────────────────

  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory AppAlert.fromJson(Map<String, dynamic> json) => AppAlert(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    severity: json['severity'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'severity': severity,
    'timestamp': timestamp.toIso8601String(),
  };

  // ── copyWith ───────────────────────────────────────────────────────────────

  AppAlert copyWith({
    String? id,
    String? title,
    String? description,
    String? severity,
    DateTime? timestamp,
  }) => AppAlert(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    severity: severity ?? this.severity,
    timestamp: timestamp ?? this.timestamp,
  );

  // ── Equality & debug ───────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppAlert && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AppAlert(id: $id, title: "$title", severity: $severity, '
      'timestamp: $timestamp)';
}
