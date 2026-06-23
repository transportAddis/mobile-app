import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/providers/transit_provider.dart';
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
        ChangeNotifierProvider(create: (_) => TransitProvider()),
        // Task 3: ChangeNotifierProvider(create: (_) => JourneyProvider()),
        // Task 4: ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Transit Addis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // TODO(Task 3): Replace with go_router or named routes.
        home: const LoginScreen(),
      ),
    );
  }
}

/// Temporary scaffold – validates theme + provider wiring before the real
/// shell is built in Task 3.
class _AppPlaceholder extends StatefulWidget {
  const _AppPlaceholder();

  @override
  State<_AppPlaceholder> createState() => _AppPlaceholderState();
}

class _AppPlaceholderState extends State<_AppPlaceholder> {
  @override
  void initState() {
    super.initState();
    // Kick off the data load as soon as the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransitProvider>().fetchMockData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransitProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Transit Addis')),
      body: Center(
        child: provider.isLoading
            ? const CircularProgressIndicator()
            : provider.hasError
            ? Text(provider.error!, style: TextStyle(color: colors.error))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${provider.routes.length} routes · '
                    '${provider.alerts.length} alerts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provider OK',
                    style: AppTextStyles.mono(
                      fontSize: 14,
                      color: AppColors.crowdLow,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
