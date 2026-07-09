import 'package:flutter/material.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/crowd_indicator_bar.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    this.onTap,
    this.isBest = false,
  });

  final TransitRoute route;
  final VoidCallback? onTap;

  /// True when this is the recommended/fastest route (index 0 from
  /// TransitProvider.routes). Renders a small "FASTEST" badge at the
  /// top-left of the card.
  final bool isBest;

  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(16));

  static String _queueStatusText(CrowdLevel l) => switch (l) {
    CrowdLevel.low => 'Short Wait',
    CrowdLevel.medium => 'Moderate Wait',
    CrowdLevel.high => 'High Wait Time',
  };

  static String _occupancyStatusText(CrowdLevel l) => switch (l) {
    CrowdLevel.low => 'Seats Available',
    CrowdLevel.medium => 'Moderately Full',
    CrowdLevel.high => 'Standing Only',
  };

  static IconData _iconFor(String type) => type == 'City Bus'
      ? Icons.directions_bus_rounded
      : Icons.airport_shuttle_rounded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: _cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── "FASTEST" badge (top-left, only for the best route) ────────
              if (isBest) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FASTEST',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Top row ────────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconFor(route.type),
                      size: 20,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        route.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${route.etaMinutes} min',
                        style: AppTextStyles.mono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          route.fareAmount,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Type badge ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  route.type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // ── Station timeline ───────────────────────────────────────────
              if (route.stationNames.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Stops',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < route.stationNames.length; i++) ...[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    (i == 0 ||
                                        i == route.stationNames.length - 1)
                                    ? route.routeColor
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: route.routeColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              route.stationNames[i],
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (i < route.stationNames.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Container(
                              width: 28,
                              height: 2,
                              color: route.routeColor.withValues(alpha: 0.40),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Crowd indicators ───────────────────────────────────────────
              CrowdIndicatorBar(
                level: route.stationQueueLevel,
                label: 'Station Queue',
                statusLabel: _queueStatusText(route.stationQueueLevel),
              ),
              const SizedBox(height: 12),
              CrowdIndicatorBar(
                level: route.vehicleOccupancyLevel,
                label: 'Incoming Vehicle',
                statusLabel: _occupancyStatusText(route.vehicleOccupancyLevel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
