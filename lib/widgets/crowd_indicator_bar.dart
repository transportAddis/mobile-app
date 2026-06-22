import 'package:flutter/material.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CrowdIndicatorBar
//
// Renders a labelled horizontal progress bar for a CrowdLevel value.
// Used inside RouteCard twice: once for station queue, once for vehicle
// occupancy.  The optional [statusLabel] lets callers override the generic
// "Low / Medium / High" chip with context-specific copy
// e.g. "Seats Available", "Standing Only", "Moderate Wait".
//
// Usage:
//   CrowdIndicatorBar(
//     level: route.stationQueueLevel,
//     label: 'Station Queue',
//     statusLabel: 'High Wait Time',   // optional
//   )
// ─────────────────────────────────────────────────────────────────────────────

class CrowdIndicatorBar extends StatelessWidget {
  const CrowdIndicatorBar({
    super.key,
    required this.level,
    required this.label,
    this.statusLabel,
  });

  final CrowdLevel level;

  /// Left-side context label, e.g. "Station Queue", "Incoming Vehicle".
  final String label;

  /// Right-side status chip. Defaults to the level name ("Low", "Medium",
  /// "High") when omitted.
  final String? statusLabel;

  // ── Design tokens ──────────────────────────────────────────────────────────

  /// Fill fractions matching the spec: Low 20%, Medium 60%, High 90%.
  static const Map<CrowdLevel, double> _fractions = {
    CrowdLevel.low: 0.20,
    CrowdLevel.medium: 0.60,
    CrowdLevel.high: 0.90,
  };

  static const Map<CrowdLevel, Color> _fillColors = {
    CrowdLevel.low: AppColors.crowdLow,
    CrowdLevel.medium: AppColors.crowdMedium,
    CrowdLevel.high: AppColors.crowdHigh,
  };

  static const Map<CrowdLevel, String> _defaultLabels = {
    CrowdLevel.low: 'Low',
    CrowdLevel.medium: 'Medium',
    CrowdLevel.high: 'High',
  };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fillColor = _fillColors[level]!;
    final fraction = _fractions[level]!;
    final chipText = statusLabel ?? _defaultLabels[level]!;
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    // Track is a low-opacity wash of the foreground colour so it adapts to
    // both light (#0b0504 at 8%) and dark (#fbf5f4 at 8%) card surfaces.
    final trackColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label row ─────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(color: mutedColor),
            ),
            Text(
              chipText,
              style: textTheme.labelMedium?.copyWith(
                color: fillColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ── Progress track ────────────────────────────────────────────────────
        // LayoutBuilder gives us the real available width so FractionallySized-
        // Box isn't needed; AnimatedContainer handles live level transitions.
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Track (full width, background)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                // Fill (animated fraction)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * fraction,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
