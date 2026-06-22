import 'package:flutter/material.dart';

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

  static const List<_NavItemData> _items = [
    _NavItemData(
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Saved',
      activeIcon: Icons.bookmark_rounded,
      inactiveIcon: Icons.bookmark_border,
    ),
    _NavItemData(
      label: 'Settings',
      activeIcon: Icons.settings_rounded,
      inactiveIcon: Icons.settings_outlined,
    ),
  ];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top border line (replaces Material elevation shadow)
        Container(height: 1, color: borderColor),
        BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          // Active / inactive colours come from AppTheme.bottomNavigationBarTheme
          // (primary + unselected). Redeclare here so the widget is
          // self-contained if extracted to another project.
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.unselected,
          items: List.generate(_items.length, (i) {
            final item = _items[i];
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
// _NavItemData  (private data class; avoids parallel lists)
// ─────────────────────────────────────────────────────────────────────────────

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
}
