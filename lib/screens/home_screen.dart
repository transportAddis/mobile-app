import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/screens/search_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/route_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _toText = '';
  final MapController _mapController = MapController();

  final List<LatLng> _path1 = const [
    LatLng(9.0248, 38.8680),
    LatLng(9.0195, 38.8005),
    LatLng(9.0142, 38.7808),
    LatLng(9.0103, 38.7617),
    LatLng(9.0100, 38.7450),
  ];
  final List<LatLng> _path2 = const [
    LatLng(9.0248, 38.8680),
    LatLng(8.9950, 38.8100),
    LatLng(8.9890, 38.7890),
    LatLng(9.0103, 38.7617),
    LatLng(9.0100, 38.7450),
  ];
  final List<LatLng> _path3 = const [
    LatLng(9.0248, 38.8680),
    LatLng(9.0400, 38.8300),
    LatLng(9.0350, 38.7650),
    LatLng(9.0320, 38.7520),
    LatLng(9.0100, 38.7450),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TransitProvider>();
      p.fetchMockData();
      p.fetchNearbyStations(9.0248, 38.8680);
    });
  }

  LatLng _midpoint(List<LatLng> points) => points.isEmpty
      ? const LatLng(9.0174, 38.8065)
      : points[points.length ~/ 2];

  void _showRouteDetails(TransitRoute route) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.20),
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

  Future<void> _openSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const SearchScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _toText = result);
      _mapController.move(const LatLng(9.0174, 38.8065), 11.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransitProvider>();
    final cs = Theme.of(context).colorScheme;

    final List<Polyline> polylines = [];
    final List<Marker> markers = [];

    if (_toText.isNotEmpty && provider.routes.isNotEmpty) {
      final paths = [_path1, _path2, _path3];

      for (int i = 0; i < 3 && i < provider.routes.length; i++) {
        final route = provider.routes[i];
        final path = paths[i];

        // ── Polyline ────────────────────────────────────────────────────────
        polylines.add(
          Polyline(points: path, color: route.routeColor, strokeWidth: 5.0),
        );

        // ── Station node markers (white circle, colored border) ─────────────
        for (final point in path) {
          markers.add(
            Marker(
              point: point,
              width: 16,
              height: 16,
              alignment: Alignment.center,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: route.routeColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── Midpoint pill badge ──────────────────────────────────────────────
        // FIX: width 220, Text wrapped in Flexible with ellipsis
        markers.add(
          Marker(
            point: _midpoint(path),
            width: 220,
            height: 40,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _showRouteDetails(route),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: route.routeColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${route.name} • ${route.etaMinutes}m',
                        style: AppTextStyles.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(9.0174, 38.8065),
              initialZoom: 11.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttransit.addis',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // Floating search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(32),
                color: cs.surface,
                child: InkWell(
                  onTap: _openSearch,
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _toText.isEmpty ? 'Where to?' : 'To: $_toText',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: _toText.isEmpty
                                      ? cs.onSurfaceVariant
                                      : cs.onSurface,
                                  fontSize: 18,
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
                                const LatLng(9.0174, 38.8065),
                                11.5,
                              );
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: cs.onSurfaceVariant,
                              size: 20,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.directions_bus_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // My Location FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              backgroundColor: cs.surface,
              foregroundColor: cs.primary,
              elevation: 4,
              onPressed: () =>
                  _mapController.move(const LatLng(9.0174, 38.8065), 11.5),
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
