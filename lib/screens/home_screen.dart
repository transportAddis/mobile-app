import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/models/transit_route.dart';
import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/screens/search_screen.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/widgets/route_card.dart';

// Meskel Square — used both as the default map fallback centre and the
// coordinate we query nearby-stations from when GPS isn't available.
const LatLng _kMeskelSquare = LatLng(9.0103, 38.7617);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String              _toText        = '';
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  bool    _isLocating = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TransitProvider>();
      p.fetchAllStations();
      // Auto-attempt geolocation on launch — falls back to Meskel Square
      // internally if GPS is denied/unavailable/errors out.
      _getCurrentLocation();
    });
  }

  // ── GPS ───────────────────────────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    // Captured before any `await` so we never touch context across an
    // async gap.
    final transitProvider = context.read<TransitProvider>();

    Future<void> useFallback([String? message]) async {
      if (message != null) _showSnack(message);
      _mapController.move(_kMeskelSquare, 13.5);
      await transitProvider.fetchNearbyStations(
        _kMeskelSquare.latitude,
        _kMeskelSquare.longitude,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await useFallback(
          'Location services are off — showing stations near Meskel Square.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await useFallback(
            'Location permission denied — showing stations near Meskel Square.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await useFallback(
          'Location permission permanently denied — showing stations near Meskel Square.',
        );
        return;
      }

      // Permission granted — resolve the real device coordinate.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final userLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _currentLocation = userLatLng);
      _mapController.move(userLatLng, 15.0);

      await transitProvider.fetchNearbyStations(
        userLatLng.latitude,
        userLatLng.longitude,
      );
    } catch (e) {
      // Any unexpected exception also falls back to Meskel Square.
      await useFallback(
        'Could not get your location — showing stations near Meskel Square.',
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  LatLng _midpoint(List<LatLng> points) =>
      points.isEmpty ? _kMeskelSquare : points[points.length ~/ 2];

  String _resolveDestinationId(String result) => result;

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showRouteDetails(TransitRoute route, {required bool isBest}) {
    // The modal bottom sheet's own BuildContext may sit outside the
    // MultiProvider's subtree depending on how the Navigator is configured,
    // so we capture the EXISTING TransitProvider instance here and
    // explicitly re-inject it via ChangeNotifierProvider.value below,
    // rather than relying on ambient lookup inside the sheet.
    final transitProvider = context.read<TransitProvider>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider<TransitProvider>.value(
        value: transitProvider,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              RouteCard(route: route, isBest: isBest),
              const SizedBox(height: 16),
              // Save/Unsave button — Consumer so it flips immediately after
              // a tap without closing the sheet.
              Consumer<TransitProvider>(
                builder: (context, provider, _) {
                  final isSaved = provider.isRouteSaved(route.id);
                  return isSaved
                      ? OutlinedButton.icon(
                          onPressed: () => _handleToggleSave(context, route),
                          icon: const Icon(Icons.bookmark_remove_outlined),
                          label: const Text('Remove from Saved'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _handleToggleSave(context, route),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Save this Route'),
                        );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _handleToggleSave(BuildContext context, TransitRoute route) {
    final provider = context.read<TransitProvider>();
    final wasSaved  = provider.isRouteSaved(route.id);
    provider.toggleSaveRoute(route);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasSaved ? 'Route removed from your favorites' : 'Route saved to your favorites',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Search → local route engine ─────────────────────────────────────────────

  Future<void> _openSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const SearchScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;

    setState(() => _toText = result);

    final provider = context.read<TransitProvider>();
    final destinationId          = _resolveDestinationId(result);
    final activeNearbyStationIds =
        provider.nearbyStations.map((s) => s.id).toList();

    await provider.searchRoutes(destinationId, activeNearbyStationIds);

    if (!mounted) return;

    if (provider.hasError && provider.routes.isEmpty) {
      _showSnack(provider.error!);
      return;
    }
    if (provider.routes.isEmpty) return;

    final firstPath = provider.routes.first.coordinates;
    if (firstPath.isNotEmpty) {
      _mapController.move(_midpoint(firstPath), 12.0);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransitProvider>();
    final cs        = Theme.of(context).colorScheme;

    final String searchBarLabel = _toText.isEmpty
        ? 'Where to?'
        : provider.hasError
            ? 'No route found — try again'
            : (provider.routes.isNotEmpty && provider.routes.first.stationNames.isNotEmpty)
                ? 'To: ${provider.routes.first.stationNames.last}'
                : 'Searching route…';

    final List<Marker>   markers   = [];
    final List<Polyline> polylines = [];

    // ── 1. Grey station pins for every station near the user ──────────────────
    if (provider.hasNearbyStations) {
      for (final station in provider.nearbyStations) {
        if (station.latitude == 0.0 && station.longitude == 0.0) continue;
        markers.add(Marker(
          point: LatLng(station.latitude, station.longitude),
          width: 26, height: 26,
          alignment: Alignment.center,
          child: Icon(Icons.directions_bus, color: Colors.grey.shade600, size: 20),
        ));
      }
    }

    // ── 2. Route polylines + station nodes + midpoint badges ──────────────────
    // Defensive: only draw when there's an active search AND routes exist
    // AND the specific route actually has coordinates.
    if (_toText.isNotEmpty && provider.routes.isNotEmpty) {
      for (int i = 0; i < 3 && i < provider.routes.length; i++) {
        final route  = provider.routes[i];
        final path   = route.coordinates;
        if (path.isEmpty) continue;

        final isBest = i == 0;

        polylines.add(Polyline(
          points: path,
          color: route.routeColor,
          strokeWidth: isBest ? 7.0 : 5.0,
        ));

        for (final point in path) {
          markers.add(Marker(
            point: point, width: 16, height: 16, alignment: Alignment.center,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                border: Border.all(color: route.routeColor, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 3),
                ],
              ),
            ),
          ));
        }

        final badgeLabel = isBest
            ? '⭐ Best • ${route.name} • ${route.etaMinutes}m'
            : '${route.name} • ${route.etaMinutes}m';

        // Wide pill-shaped badge at the route's midpoint. Flexible + ellipsis
        // guarantees no right-overflow regardless of route name length.
        markers.add(Marker(
          point: _midpoint(path),
          width: isBest ? 240 : 220,
          height: 40,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showRouteDetails(route, isBest: isBest),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: route.routeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.mono(
                          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }

    // ── 3. Blue-dot user location (drawn last so it's on top) ─────────────────
    if (_currentLocation != null) {
      markers.add(Marker(
        point: _currentLocation!, width: 28, height: 28,
        alignment: Alignment.center,
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                blurRadius: 10, spreadRadius: 4,
              ),
              BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kMeskelSquare,
              initialZoom: 13.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            searchBarLabel,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _toText.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                              fontSize: 18,
                              fontWeight: _toText.isEmpty ? FontWeight.normal : FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_toText.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() => _toText = '');
                              _mapController.move(_kMeskelSquare, 13.5);
                            },
                            child: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 20),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_bus_rounded, color: cs.primary, size: 20),
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
            bottom: 24, right: 16,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              backgroundColor: cs.surface,
              foregroundColor: cs.primary,
              elevation: 4,
              onPressed: _isLocating ? null : _getCurrentLocation,
              child: _isLocating
                  ? SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
