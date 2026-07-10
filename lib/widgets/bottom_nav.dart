import 'package:flutter/material.dart';

import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransitBottomNav
//
// Wraps Flutter's BottomNavigationBar with:
//   • A 1px top border (matches the React `border-t border-[var(--border)]`)
//   • Filled/outlined icon pairs for active/inactive state
//   • AppColors.primary for selected, AppColors.unselected for unselected
//
// Usage in a Scaffold:
//   bottomNavigationBar: TransitBottomNav(
//     currentIndex: _selectedIndex,
//     onTap: (i) => setState(() => _selectedIndex = i),
//   )
//
// Tab indices:  0 = Home  |  1 = Saved  |  2 = Settings
// ─────────────────────────────────────────────────────────────────────────────

class TransitBottomNav extends StatelessWidget {
  const TransitBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;

  /// Receives the tapped index. Wire this to setState or a provider.
  final ValueChanged<int> onTap;

  // ── Nav item definitions ──────────────────────────────────────────────────

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final l10n = AppLocalizations.of(context)!; // Access translations [12]

    // Generate translations on the fly
    final items = [
      (
        label: l10n.home,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
      (
        label: l10n.saved,
        activeIcon: Icons.bookmark_rounded,
        inactiveIcon: Icons.bookmark_border,
      ),
      (
        label: l10n.settings,
        activeIcon: Icons.settings_rounded,
        inactiveIcon: Icons.settings_outlined,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: borderColor),
        BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.unselected,
          items: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == currentIndex;
            return BottomNavigationBarItem(
              icon: Icon(isActive ? item.activeIcon : item.inactiveIcon),
              label: item.label,
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
