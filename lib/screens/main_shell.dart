import 'package:flutter/material.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/saved_routes_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/widgets/bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // IndexedStack keeps all screens alive — FlutterMap state is preserved
      // when switching tabs because the widget is never unmounted.
      body: IndexedStack(
        index: _selectedIndex,
        children: const [HomeScreen(), SavedRoutesScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: TransitBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
