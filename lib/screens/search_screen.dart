import 'package:flutter/material.dart';
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

  // Mock Database of Addis Ababa Locations for Auto-complete
  final List<String> _allLocations = [
    'Ayat Station',
    'CMC Station',
    'Megenagna',
    'Piassa',
    'Bole Airport',
    'Stadium',
    'Mexico Square',
    'Merkato',
    'Sarbet',
    'Kera',
    '4 Kilo',
    '6 Kilo',
    'Shiromeda',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to typing to update the auto-complete list
    _destinationController.addListener(() {
      setState(() {
        _searchQuery = _destinationController.text;
      });
    });

    // Auto-focus the keyboard as soon as the screen opens
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

  void _selectLocation(String location) {
    // AUTO-SUBMIT: Instantly close the screen and send the location string back!
    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Filter logic: If query is empty, show recent. If typing, show matches.
    final filteredLocations = _searchQuery.isEmpty
        ? ['Piassa', 'Bole Airport', 'Mexico Square'] // Recent searches
        : _allLocations
              .where(
                (loc) => loc.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Header
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

            // Auto-complete List
            Expanded(
              child: ListView.builder(
                itemCount: filteredLocations.length,
                itemBuilder: (context, index) {
                  final location = filteredLocations[index];
                  return ListTile(
                    leading: Icon(
                      _searchQuery.isEmpty
                          ? Icons.history
                          : Icons.location_on_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                    title: Text(location, style: const TextStyle(fontSize: 16)),
                    // Tap triggers the auto-submit
                    onTap: () => _selectLocation(location),
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
