import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/models/nearby_station.dart';
import 'package:mobile_app/providers/transit_provider.dart';
import 'package:mobile_app/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  // NOTE: the hardcoded _allLocations list is gone — autocomplete now reads
  // live from TransitProvider.allStations (populated by fetchAllStations()
  // in HomeScreen.initState).

  @override
  void initState() {
    super.initState();
    _destinationController.addListener(() {
      setState(() => _searchQuery = _destinationController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Returns the station's real database ID (a UUID), not just its name, so
  /// HomeScreen can call TransitProvider.searchRoutes with a precise
  /// destination the backend actually recognizes.
  void _selectLocation(NearbyStation station) {
    Navigator.pop(context, station.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allStations = context.watch<TransitProvider>().allStations;

    final filteredStations = _searchQuery.isEmpty
        ? allStations
        : allStations
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top search header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _destinationController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Where to?',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: AppColors.crowdHigh,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _destinationController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results list ──────────────────────────────────────────────────
            Expanded(
              // allStations.isEmpty doubles as a simple loading proxy — the
              // cache is populated once on app open and is normally ready by
              // the time the user reaches this screen.
              child: allStations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStations.isEmpty
                  ? Center(
                      child: Text(
                        'No stations found',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredStations.length,
                      itemBuilder: (context, index) {
                        final station = filteredStations[index];
                        return ListTile(
                          leading: Icon(
                            Icons.directions_bus_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                          title: Text(
                            station.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () => _selectLocation(station),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
