import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/screens/search_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/route_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
//
// Map-first screen. Bottom nav state is now owned by MainShell via
// IndexedStack, so this widget is purely responsible for:
//   • The FlutterMap base layer
//   • Color-coded Polylines + midpoint Marker badges
//   • The floating search card → SearchScreen push
//   • showModalBottomSheet with RouteCard on badge tap
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _toText = '';
  final MapController _mapController = MapController();

  // Mock route coordinates (Ayat → CMC → Megenagna → Stadium).
  // Task 8: replace with real LatLng arrays from the backend route response.
  final List<LatLng> _routeCoordinates = const [
    LatLng(9.0248, 38.7469), // Ayat Station
    LatLng(9.0200, 38.7400), // CMC
    LatLng(9.0150, 38.7200), // Megenagna
    LatLng(9.0100, 38.7000), // Stadium
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TransitProvider>();
      p.fetchMockData();
      p.fetchNearbyStations(9.0248, 38.7469);
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Index-based midpoint — anchors the pill badge on the polyline.
  LatLng _midpoint(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(9.0248, 38.7469);
    return points[points.length ~/ 2];
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showRouteDetails(TransitRoute route) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          // FIX: cardColor is deprecated in M3 — use colorScheme.surface
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            RouteCard(route: route),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Search navigation ──────────────────────────────────────────────────────

  Future<void> _openSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const SearchScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _toText = result);
      _mapController.move(_midpoint(_routeCoordinates), 13.5);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransitProvider>();
    final cs       = Theme.of(context).colorScheme;

    final List<Polyline> polylines = [];
    final List<Marker>   markers   = [];

    if (_toText.isNotEmpty && provider.routes.isNotEmpty) {
      for (int i = 0; i < 3 && i < provider.routes.length; i++) {
        final route = provider.routes[i];

        polylines.add(Polyline(
          points:      _routeCoordinates,
          color:       route.routeColor,
          strokeWidth: i == 0 ? 6.0 : 4.0,
        ));

        markers.add(Marker(
          point:     _midpoint(_routeCoordinates),
          width:     140,
          height:    45,
          alignment: Alignment(0, (i - 1) * 1.5),
          child: GestureDetector(
            onTap: () => _showRouteDetails(route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:        route.routeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    route.type == 'Train'
                        ? Icons.train_rounded
                        : Icons.directions_bus_rounded,
                    color: Colors.white,
                    size:  14,
                  ),
                  const SizedBox(width: 4),
                  // FIX: use AppTextStyles.mono() instead of raw fontFamily string
                  Text(
                    '${route.name.split(' ').last} • ${route.etaMinutes}m',
                    style: AppTextStyles.mono(
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }

    return Scaffold(
      // Prevent map from resizing when keyboard opens on pushed SearchScreen
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── 1. Full-screen OSM map ─────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(9.0248, 38.7469),
              initialZoom:   14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttransit.addis',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // ── 2. Floating search bar ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                elevation:     6,
                shadowColor:   Colors.black.withValues(alpha: 0.20),
                borderRadius:  BorderRadius.circular(32),
                color:         cs.surface,
                child: InkWell(
                  onTap:        _openSearch,
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical:   14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _toText.isEmpty ? 'Where to?' : 'To: $_toText',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color:      _toText.isEmpty
                                      ? cs.onSurfaceVariant
                                      : cs.onSurface,
                                  fontSize:   18,
                                  fontWeight: _toText.isEmpty
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_toText.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() => _toText = '');
                              _mapController.move(
                                const LatLng(9.0248, 38.7469),
                                14.0,
                              );
                            },
                            child: Icon(Icons.close_rounded,
                                color: cs.onSurfaceVariant, size: 20),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_bus_rounded,
                                color: cs.primary, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. My Location FAB ─────────────────────────────────────────────
          Positioned(
            bottom: 24,
            right:  16,
            child: FloatingActionButton(
              heroTag:         'myLocation',
              backgroundColor: cs.surface,
              foregroundColor: cs.primary,
              elevation:       4,
              onPressed: () => _mapController.move(
                const LatLng(9.0248, 38.7469),
                14.0,
              ),
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
