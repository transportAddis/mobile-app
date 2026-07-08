import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;

  void _onLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Profile ───────────────────────────────────────────────────
              Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'AK',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Abebe Kebede',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+251 911 234 567',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Settings card ─────────────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outline.withValues(alpha: 0.40)),
                ),
                child: Column(
                  children: [
                    // Language
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: const Text('Language'),
                      subtitle: const Text('English'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),

                    // ── Theme selector ────────────────────────────────────────
                    // FIX: SegmentedButton lives below the title in a Padding
                    // block so it can expand to the full card width.
                    // Icons removed from ButtonSegments — text-only gives each
                    // segment room to breathe without wrapping.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.brightness_6_rounded,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Theme', style: theme.textTheme.bodyLarge),
                                const SizedBox(height: 10),
                                // Full-width SegmentedButton, text labels only
                                SegmentedButton<ThemeMode>(
                                  expandedInsets: EdgeInsets.zero,
                                  style: SegmentedButton.styleFrom(
                                    selectedBackgroundColor: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    selectedForegroundColor: AppColors.primary,
                                    side: BorderSide(
                                      color: cs.outline.withValues(alpha: 0.40),
                                    ),
                                    textStyle: theme.textTheme.labelMedium,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  segments: const [
                                    ButtonSegment(
                                      value: ThemeMode.light,
                                      label: Text('Light'),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.system,
                                      label: Text('Auto'),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.dark,
                                      label: Text('Dark'),
                                    ),
                                  ],
                                  selected: {themeProvider.themeMode},
                                  onSelectionChanged: (modes) => context
                                      .read<ThemeProvider>()
                                      .setThemeMode(modes.first),
                                  showSelectedIcon: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),

                    // Push Notifications
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_rounded),
                      title: const Text('Push Notifications'),
                      value: _pushNotifications,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) =>
                          setState(() => _pushNotifications = val),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),

                    // Privacy Policy
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Logout ────────────────────────────────────────────────────
              OutlinedButton(
                onPressed: _onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
