import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/screens/search_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Map-First (Uber / Google Maps pattern)
//
// Stack layers (bottom → top):
//   1. FlutterMap  — full-screen OSM base map
//   2. PolylineLayer  — empty now; Task 6 populates with route polylines
//   3. SafeArea + floating search card  — always on top of the map
//
// Scaffold slots:
//   • bottomNavigationBar: TransitBottomNav
//   • floatingActionButton: My Location (bottom-right, above nav bar)
// ─────────────────────────────────────────────────────────────────────────────

// Addis Ababa city centre
const _kAddisAbaba = LatLng(9.0248, 38.7469);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  int _selectedIndex = 0;

  /// Selected destination name — shown inside the floating search card.
  /// Null = placeholder "Where to?" is shown.
  String? _destination;

  /// Color-coded route polylines drawn on the map.
  /// Empty until Task 6 wires up the route API response.
  ///
  /// Task 6: call _buildPolylines(provider.routes) after destination selected.
  /// Blue  → Train routes  (AppColors.primary adjacent)
  /// Orange → Bus routes   (AppColors.crowdMedium)
  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TransitProvider>();
      p.fetchMockData();
      // Addis Ababa centre — real GPS coordinates injected in Task 7.
      p.fetchNearbyStations(9.0248, 38.7469);
    });
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    // TODO(Task 8): push SavedScreen (1) and SettingsScreen (2).
  }

  Future<void> _onSearchTap() async {
    final destination = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const SearchScreen(),
        fullscreenDialog: true,
      ),
    );
    if (destination != null && mounted) {
      setState(() => _destination = destination);
      // Task 6: _buildPolylines(destination) goes here.
    }
  }

  void _onClearDestination() => setState(() => _destination = null);

  void _onMyLocation() {
    // TODO(Task 7): request real GPS via geolocator, then move map.
    _mapController.move(_kAddisAbaba, 15.0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // Prevent the map from resizing when the system keyboard opens
      // (SearchScreen handles its own keyboard inset).
      resizeToAvoidBottomInset: false,

      bottomNavigationBar: TransitBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),

      // My Location FAB — Flutter automatically lifts it above the nav bar.
      floatingActionButton: FloatingActionButton(
        heroTag: 'myLocation',
        backgroundColor: cs.surface,
        foregroundColor: cs.primary,
        elevation: 4,
        onPressed: _onMyLocation,
        child: const Icon(Icons.my_location_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Stack(
        children: [
          // ── Layer 1: Full-screen OSM map ─────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _kAddisAbaba,
              initialZoom: 14.0,
            ),
            children: [
              // Base tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // Must identify the app to OSM tile servers per usage policy.
                userAgentPackageName: 'com.smarttransit.mobile_app',
              ),

              // ── Layer 2: Route polylines (Task 6 populates this) ──────────
              // Blue  = Train  (use const Color(0xFF1565C0))
              // Orange = Bus   (use AppColors.crowdMedium)
              PolylineLayer(polylines: _polylines),

              // OSM attribution — required by tile usage policy.
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
                alignment: Alignment.bottomLeft,
              ),
            ],
          ),

          // ── Layer 3: Floating search card ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _FloatingSearchCard(
                  destination: _destination,
                  onTap: _onSearchTap,
                  onClear: _onClearDestination,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FloatingSearchCard
//
// Tappable card that floats over the map at the top of the screen.
// Shows "Where to?" placeholder or the selected destination name + clear ×.
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingSearchCard extends StatelessWidget {
  const _FloatingSearchCard({
    required this.destination,
    required this.onTap,
    required this.onClear,
  });

  final String? destination;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool hasDestination = destination != null;

    return Material(
      // Use theme surface — NOT hardcoded white.
      color: cs.surface,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Search / pin icon
              Icon(
                hasDestination ? Icons.place_rounded : Icons.search_rounded,
                color: cs.primary,
                size: 22,
              ),
              const SizedBox(width: 12),

              // Destination text or placeholder
              Expanded(
                child: Text(
                  hasDestination ? destination! : 'Where to?',
                  style: hasDestination
                      ? textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                      : textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Clear button (only when destination is set)
              if (hasDestination)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                )
              else
                // Mic icon matches the Google Maps / Uber pattern
                Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
