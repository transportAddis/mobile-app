import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/screens/main_shell.dart';
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
      providers: [ChangeNotifierProvider(create: (_) => TransitProvider())],
      child: MaterialApp(
        title: 'Smart Transit Addis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainShell(),
      ),
    );
  }
}
