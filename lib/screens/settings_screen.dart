import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _onLogout(AppLocalizations l10n) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // Shows an elegant dialog to toggle languages on tap [11, 12]
  void _showLanguageDialog(BuildContext context, ThemeProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.language,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              // FIX: Replaced deprecated Radio with an elegant checkmark
              trailing: provider.locale.languageCode == 'en'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('አማርኛ (Amharic)'),
              trailing: provider.locale.languageCode == 'am'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () {
                provider.setLocale(const Locale('am'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(
      context,
    )!; // Access Amharic/English translations [12]

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    // Language selection row
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: Text(l10n.language),
                      subtitle: Text(
                        themeProvider.locale.languageCode == 'am'
                            ? 'አማርኛ'
                            : 'English',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLanguageDialog(context, themeProvider),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),

                    // Theme selector row [11]
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
                                Text(
                                  l10n.settings,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 10),
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
                                  segments: [
                                    ButtonSegment(
                                      value: ThemeMode.light,
                                      label: Text(l10n.light),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.system,
                                      label: Text(l10n.auto),
                                    ),
                                    ButtonSegment(
                                      value: ThemeMode.dark,
                                      label: Text(l10n.dark),
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

                    // Privacy Policy
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.privacyPolicy),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Logout ────────────────────────────────────────────────────
              OutlinedButton(
                onPressed: () => _onLogout(l10n),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                child: Text(l10n.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
