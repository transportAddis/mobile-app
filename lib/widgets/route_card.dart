import 'package:flutter/material.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/crowd_indicator_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RouteCard
//
// Displays a single TransitRoute with:
//   • Mode icon + route name (top-left)
//   • ETA in JetBrains Mono + fare pill (top-right)
//   • Type badge (Train / Smart Bus)
//   • Two CrowdIndicatorBars: station queue + vehicle occupancy
//
// Matches the layout of components/transit/route-card.tsx.
// The card uses border-radius 16 (rounded-2xl) to match the React prototype,
// overriding the global 12px theme default for this specific component.
// ─────────────────────────────────────────────────────────────────────────────

class RouteCard extends StatelessWidget {
  const RouteCard({super.key, required this.route, this.onTap});

  final TransitRoute route;

  /// Navigate to the live tracking screen. Null disables the tap ripple.
  final VoidCallback? onTap;

  // rounded-2xl = 16px in Tailwind
  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(16));

  // ── Status text helpers (matches React statusText copy) ───────────────────

  static String _queueStatusText(CrowdLevel level) => switch (level) {
    CrowdLevel.low => 'Short Wait',
    CrowdLevel.medium => 'Moderate Wait',
    CrowdLevel.high => 'High Wait Time',
  };

  static String _occupancyStatusText(CrowdLevel level) => switch (level) {
    CrowdLevel.low => 'Seats Available',
    CrowdLevel.medium => 'Moderately Full',
    CrowdLevel.high => 'Standing Only',
  };

  // ── Icon mapping ──────────────────────────────────────────────────────────

  static IconData _iconFor(String type) =>
      type == 'Train' ? Icons.train_rounded : Icons.directions_bus_rounded;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      // Override the global 12px theme radius for this specific card
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
              _TopRow(route: route, cs: cs, theme: theme),
              const SizedBox(height: 12),
              _TypeBadge(type: route.type, cs: cs, theme: theme),
              const SizedBox(height: 16),
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

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets  (keep RouteCard.build readable at a glance)
// ─────────────────────────────────────────────────────────────────────────────

class _TopRow extends StatelessWidget {
  const _TopRow({required this.route, required this.cs, required this.theme});

  final TransitRoute route;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode icon container (w-10 h-10 rounded-xl bg-transit-bg)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            RouteCard._iconFor(route.type),
            size: 20,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        // Route name (expands to fill remaining space)
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
        // ETA + fare pill (top-right column)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ETA in JetBrains Mono – it's a number/timer
            Text(
              '${route.etaMinutes} min',
              style: AppTextStyles.mono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            // Fare pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.cs, required this.theme});

  final String type;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        type,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
