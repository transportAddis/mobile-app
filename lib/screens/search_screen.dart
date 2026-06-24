import 'package:flutter/material.dart';

import 'package:mobile_app/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen — Auto-complete destination picker
//
// Opens as a full-screen dialog over the map.
// The TextField auto-focuses on entry and filters [_kAllLocations] on every
// keystroke. Tapping a result calls Navigator.pop<String>(context, name) so
// HomeScreen receives the selection.
//
// Task 6 prep:
//   The returned String (destination name) will be converted to a LatLng by
//   the backend geocode API, which then returns the set of route options
//   (Train / Bus polyline points) to draw on the map.
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  // ── Mock Addis Ababa location dataset ─────────────────────────────────────
  // Task 7: replace with a geocoding API call (e.g. Nominatim + debounce).

  static const List<_Location> _kAllLocations = [
    // Light Rail stations
    _Location(name: 'Ayat Station', category: 'Light Rail'),
    _Location(name: 'Meri Station', category: 'Light Rail'),
    _Location(name: 'Summit Station', category: 'Light Rail'),
    _Location(name: 'Lebu Station', category: 'Light Rail'),
    _Location(name: 'Torhailoch Station', category: 'Light Rail'),
    _Location(name: 'Kaliti Station', category: 'Light Rail'),
    _Location(name: 'Qality Station', category: 'Light Rail'),
    _Location(name: 'Akaki Station', category: 'Light Rail'),
    _Location(name: 'Lideta Station', category: 'Light Rail'),
    _Location(name: 'Meskel Square', category: 'Light Rail'),
    _Location(name: 'Stadium Station', category: 'Light Rail'),

    // Neighbourhoods & landmarks
    _Location(name: 'Megenagna', category: 'Neighbourhood'),
    _Location(name: 'Piassa', category: 'Neighbourhood'),
    _Location(name: 'Bole', category: 'Neighbourhood'),
    _Location(name: 'Bole Michael', category: 'Neighbourhood'),
    _Location(name: 'Merkato', category: 'Neighbourhood'),
    _Location(name: 'Mexico Square', category: 'Neighbourhood'),
    _Location(name: 'Lamberet', category: 'Neighbourhood'),
    _Location(name: 'Gerji', category: 'Neighbourhood'),
    _Location(name: 'CMC', category: 'Neighbourhood'),
    _Location(name: 'Gofa', category: 'Neighbourhood'),
    _Location(name: 'Kera', category: 'Neighbourhood'),
    _Location(name: 'Kolfe', category: 'Neighbourhood'),
    _Location(name: 'Nifas Silk', category: 'Neighbourhood'),
    _Location(name: 'Sarbet', category: 'Neighbourhood'),
    _Location(name: 'Shiro Meda', category: 'Neighbourhood'),
    _Location(name: 'Entoto', category: 'Neighbourhood'),
    _Location(name: 'Jemo', category: 'Neighbourhood'),
    _Location(name: 'Welo Sefer', category: 'Neighbourhood'),
    _Location(name: 'Atlas', category: 'Neighbourhood'),
    _Location(name: 'Hayat', category: 'Neighbourhood'),

    // Landmarks
    _Location(name: 'Bole International Airport', category: 'Landmark'),
    _Location(name: 'African Union HQ', category: 'Landmark'),
    _Location(name: 'National Museum', category: 'Landmark'),
    _Location(name: 'Holy Trinity Cathedral', category: 'Landmark'),
    _Location(name: 'Addis Ababa University', category: 'Landmark'),
    _Location(name: 'Black Lion Hospital', category: 'Landmark'),
    _Location(name: 'Friendship Square', category: 'Landmark'),
  ];

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<_Location> get _filtered {
    if (_query.isEmpty) return _kAllLocations;
    final q = _query.toLowerCase();
    return _kAllLocations
        .where((l) => l.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _query = _controller.text));
    // Auto-focus the search field as soon as the screen is visible.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _selectLocation(_Location location) =>
      Navigator.pop<String>(context, location.name);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The search card at the top is the "AppBar" — no system AppBar needed.
      body: Column(
        children: [
          // ── Pinned search header ──────────────────────────────────────────
          _SearchHeader(
            controller: _controller,
            focusNode: _focusNode,
            onBack: () => Navigator.pop(context),
          ),

          // ── Results list ──────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(query: _query)
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final loc = _filtered[index];
                      return _LocationTile(
                        location: loc,
                        query: _query,
                        onTap: () => _selectLocation(loc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchHeader
// Pinned card with back arrow + search TextField.
// rounded-b-3xl (28px) matches the React prototype shadow card.
// ─────────────────────────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      // Theme-aware surface — no hardcoded white.
      color: cs.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              // Back arrow
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
                visualDensity: VisualDensity.compact,
                color: cs.onSurface,
              ),
              const SizedBox(width: 4),

              // Search field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    style: textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search a destination…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: cs.primary,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: controller.clear,
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 13,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocationTile
// ListTile with a category icon and highlighted query match in the name.
// ─────────────────────────────────────────────────────────────────────────────

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.query,
    required this.onTap,
  });

  final _Location location;
  final String query;
  final VoidCallback onTap;

  static IconData _iconFor(String category) => switch (category) {
    'Light Rail' => Icons.train_rounded,
    'Landmark' => Icons.place_rounded,
    _ => Icons.location_on_outlined, // Neighbourhood
  };

  /// Highlights the matched [query] substring in bold primary colour.
  Widget _buildTitle(BuildContext context) {
    if (query.isEmpty) {
      return Text(location.name, style: Theme.of(context).textTheme.bodyMedium);
    }

    final lower = location.name.toLowerCase();
    final queryLower = query.toLowerCase();
    final start = lower.indexOf(queryLower);
    if (start == -1) {
      return Text(location.name, style: Theme.of(context).textTheme.bodyMedium);
    }
    final end = start + query.length;

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          if (start > 0) TextSpan(text: location.name.substring(0, start)),
          TextSpan(
            text: location.name.substring(start, end),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (end < location.name.length)
            TextSpan(text: location.name.substring(end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _iconFor(location.category),
          size: 20,
          color: location.category == 'Light Rail'
              ? AppColors.primary
              : cs.onSurfaceVariant,
        ),
      ),
      title: _buildTitle(context),
      subtitle: Text(
        location.category,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.40),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Location  (private data class)
// ─────────────────────────────────────────────────────────────────────────────

class _Location {
  const _Location({required this.name, required this.category});
  final String name;
  final String category;
}
