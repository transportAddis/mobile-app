import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartTransitApp());
}

class SmartTransitApp extends StatelessWidget {
  const SmartTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Register domain providers here as tasks are completed ─────────────
        // Task 2: ChangeNotifierProvider(create: (_) => TransitProvider()),
        // Task 3: ChangeNotifierProvider(create: (_) => JourneyProvider()),
        // Task 4: ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Transit Addis',
        debugShowCheckedModeBanner: false,

        // ── Theme ─────────────────────────────────────────────────────────────
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // Follows device setting; a SettingsProvider will override this later.
        themeMode: ThemeMode.system,

        // ── Router ────────────────────────────────────────────────────────────
        // TODO(Task 3): Replace with go_router or named routes.
        home: const _AppPlaceholder(),
      ),
    );
  }
}

/// Temporary scaffold so the app compiles and shows theme colours on the
/// emulator while the real shell/nav is built in subsequent tasks.
class _AppPlaceholder extends StatelessWidget {
  const _AppPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Transit Addis')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Theme OK', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            // Crowd-level colour smoke-test
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Swatch(color: colors.primary, label: 'primary'),
                _Swatch(color: AppColors.crowdLow, label: 'low'),
                _Swatch(color: AppColors.crowdMedium, label: 'med'),
                _Swatch(color: AppColors.crowdHigh, label: 'high'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '14 min',
              style: AppTextStyles.mono(fontSize: 28, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
