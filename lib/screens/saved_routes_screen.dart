import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SavedRoutesScreen
//
// Renders TransitProvider.savedRoutes — no more mock data. A route is added
// here via the "Save this Route" button in HomeScreen's route-detail bottom
// sheet, or removed from either that same button or the small remove icon
// on each card below.
// ─────────────────────────────────────────────────────────────────────────────

class SavedRoutesScreen extends StatelessWidget {
  const SavedRoutesScreen({super.key});

  void _handleRemove(BuildContext context, TransitRoute route) {
    context.read<TransitProvider>().toggleSaveRoute(route);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route removed from your favorites'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final savedRoutes = context.watch<TransitProvider>().savedRoutes;
    final l10n = AppLocalizations.of(context)!; // Access translations [12]

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.savedRoutesTitle, // Localized [12]
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                savedRoutes.isEmpty
                    ? l10n.savedRoutesSubtitle // Localized [12]
                    : l10n.routeSavedLocally(savedRoutes.length), // Localized [12]
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: savedRoutes.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: savedRoutes.length,
                        itemBuilder: (context, index) => _SavedRouteCard(
                          route: savedRoutes[index],
                          onRemove: () =>
                              _handleRemove(context, savedRoutes[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant.withValues(alpha: 0.45);
    final l10n = AppLocalizations.of(context)!; // Access translations [12]

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline, size: 64, color: mutedColor),
            const SizedBox(height: 16),
            Text(
              l10n.noSavedRoutes, // Localized [12]
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }}

// ─────────────────────────────────────────────────────────────────────────────
// _SavedRouteCard
//
// from/to are derived from TransitRoute.stationNames (first/last stop) since
// the real model doesn't carry separate origin/destination strings.
// ─────────────────────────────────────────────────────────────────────────────

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.route, required this.onRemove});

  final TransitRoute route;
  final VoidCallback onRemove;

  Color get _queueColor => switch (route.stationQueueLevel) {
    CrowdLevel.low => AppColors.crowdLow,
    CrowdLevel.medium => AppColors.crowdMedium,
    CrowdLevel.high => AppColors.crowdHigh,
  };

  // Localized switch [12]
  String _queueLabel(AppLocalizations l10n) => switch (route.stationQueueLevel) {
    CrowdLevel.low => l10n.clear,
    CrowdLevel.medium => l10n.moderate,
    CrowdLevel.high => l10n.crowded,
  };

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!; // Access translations [12]

    final from = route.stationNames.isNotEmpty ? route.stationNames.first : '—';
    final to = route.stationNames.length > 1 ? route.stationNames.last : '—';

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
              // ── Top row: colour dot | name | queue badge | remove ──────────
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                        _queueLabel(l10n),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: _queueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove from saved',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Middle row: from → to ──────────────────────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.trip_origin_rounded,
                    size: 10,
                    color: AppColors.crowdLow,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    from,
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
                  const Icon(
                    Icons.location_on_rounded,
                    size: 10,
                    color: AppColors.crowdHigh,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      to,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Bottom row: type | ETA ──────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    route.type,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${l10n.eta} ', // Localized [12]                    style: theme.textTheme.bodySmall?.copyWith(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${route.etaMinutes} ${l10n.min}',
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
