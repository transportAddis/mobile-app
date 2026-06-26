import 'package:flutter/material.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/theme/app_theme.dart';

// ─── Mock data ────────────────────────────────────────────────────────────────
// TODO(Task 8): Load from shared_preferences instead of this list.

class _SavedRoute {
  const _SavedRoute({
    required this.name,
    required this.from,
    required this.to,
    required this.etaMinutes,
    required this.routeType,
    required this.routeColor,
    required this.queueLevel,
  });
  final String name;
  final String from;
  final String to;
  final int etaMinutes;
  final String routeType;
  final Color routeColor;
  final CrowdLevel queueLevel;
}

const List<_SavedRoute> _mockSaved = [
  _SavedRoute(
    name: 'Home to University',
    from: 'Ayat Station',
    to: 'Addis Ababa University',
    etaMinutes: 22,
    routeType: 'Smart Bus',
    routeColor: Color(0xFFDE613B),
    queueLevel: CrowdLevel.low,
  ),
  _SavedRoute(
    name: 'Commute to Piassa',
    from: 'Lebu Station',
    to: 'Piassa',
    etaMinutes: 18,
    routeType: 'Train',
    routeColor: Color(0xFF1565C0),
    queueLevel: CrowdLevel.medium,
  ),
  _SavedRoute(
    name: 'Weekend Market',
    from: 'Megenagna',
    to: 'Merkato',
    etaMinutes: 35,
    routeType: 'Smart Bus',
    routeColor: Color(0xFF00695C),
    queueLevel: CrowdLevel.high,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class SavedRoutesScreen extends StatelessWidget {
  const SavedRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Text(
              'Saved Routes',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_mockSaved.length} routes saved locally',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ..._mockSaved.map((r) => _SavedRouteCard(route: r)),
          ],
        ),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.route});
  final _SavedRoute route;

  Color get _queueColor => switch (route.queueLevel) {
    CrowdLevel.low => AppColors.crowdLow,
    CrowdLevel.medium => AppColors.crowdMedium,
    CrowdLevel.high => AppColors.crowdHigh,
  };

  String get _queueLabel => switch (route.queueLevel) {
    CrowdLevel.low => 'Clear',
    CrowdLevel.medium => 'Moderate',
    CrowdLevel.high => 'Crowded',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.40)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: route colour dot | name | queue badge ─────────────
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: route.routeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      route.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Queue status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _queueColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _queueColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _queueLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _queueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Middle row: from → to ──────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.trip_origin_rounded,
                    size: 10,
                    color: AppColors.crowdLow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    route.from,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.location_on_rounded,
                    size: 10,
                    color: AppColors.crowdHigh,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      route.to,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Bottom row: transport type | ETA ──────────────────────────
              Row(
                children: [
                  Icon(
                    route.routeType == 'Train'
                        ? Icons.train_rounded
                        : Icons.directions_bus_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    route.routeType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ETA ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${route.etaMinutes} min',
                    style: AppTextStyles.mono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
