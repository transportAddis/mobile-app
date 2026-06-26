import 'package:flutter/material.dart';

import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local UI state — Task 8: wire to a ThemeProvider / SharedPreferences
  bool _darkMode = true;
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
                  // Avatar circle with initials
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

                  // Name + verified badge
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

                  // Phone
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
                      onTap: () {
                        // TODO(Task 9 – i18n): open language picker
                      },
                    ),
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),

                    // Dark Mode toggle
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_rounded),
                      title: const Text('Dark Mode'),
                      value: _darkMode,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _darkMode = val);
                        // TODO(Task 8): update ThemeProvider so
                        // MaterialApp.themeMode reacts to this toggle.
                      },
                    ),
                    Divider(
                      height: 1,
                      color: cs.outline.withValues(alpha: 0.25),
                    ),

                    // Push Notifications toggle
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_rounded),
                      title: const Text('Push Notifications'),
                      value: _pushNotifications,
                      activeColor: AppColors.primary,
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
                      onTap: () {
                        // TODO(Task 8): launch privacy URL in WebView
                      },
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
