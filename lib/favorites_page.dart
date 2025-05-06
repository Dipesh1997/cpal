import 'package:flutter/material.dart';
import 'color_detail_page.dart';
import 'lightcolors.dart';
import 'mediumcolors.dart';
import 'darkcolors.dart';
import 'sacolors.dart';
import 'svcolors.dart';
import 'opuscolors.dart';
import 'ncscolors.dart';
import 'woodcolors.dart';

class FavoritesPage extends StatefulWidget {
  final Map<String, dynamic> allColors;
  final Set<String> favoriteColorNumbers;
  final Function(String) onFavoriteToggle;

  const FavoritesPage({
    super.key,
    required this.allColors,
    required this.favoriteColorNumbers,
    required this.onFavoriteToggle,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _favoriteColors = [];
  List<Map<String, dynamic>> _woodFavoriteColors = [];
  bool _isLoading = false;
  late TabController _tabController;
  late Map<String, List<dynamic>> _allColorsWithWood;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeColors();
    _updateFavoriteColors();
  }

  void _initializeColors() {
    debugPrint('Initializing colors...');
    // Create a new map that includes both the main colors and wood colors
    _allColorsWithWood = Map<String, List<dynamic>>.from(widget.allColors);

    // Add wood colors data only if they don't exist in the main colors
    if (!_allColorsWithWood.containsKey('asian')) {
      _allColorsWithWood['asian'] = WoodColors.colors;
    }
    if (!_allColorsWithWood.containsKey('ncs')) {
      _allColorsWithWood['ncs'] = NcsColors.colors;
    }

    debugPrint('Total categories: ${_allColorsWithWood.keys.length}');
    debugPrint('Categories: ${_allColorsWithWood.keys.join(', ')}');
    debugPrint('Favorite numbers: ${widget.favoriteColorNumbers.join(', ')}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favoriteColorNumbers != widget.favoriteColorNumbers ||
        oldWidget.allColors != widget.allColors) {
      debugPrint('Widget updated - Favorites changed');
      _initializeColors();
      _updateFavoriteColors();
    }
  }

  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _updateFavoriteColors() {
    debugPrint('Updating favorite colors...');
    // Clear existing favorites
    List<Map<String, dynamic>> favorites = [];
    List<Map<String, dynamic>> woodFavorites = [];
    Set<String> processedNumbers = {};

    // Rebuild favorites list from current state
    _allColorsWithWood.forEach((category, colors) {
      debugPrint('Processing category: $category with ${colors.length} colors');
      for (var color in colors) {
        if (color == null ||
            color['number'] == null ||
            color['value'] == null) {
          continue;
        }

        String colorNumber = color['number'].toString();
        // Skip if we've already processed this color number
        if (processedNumbers.contains(colorNumber)) {
          continue;
        }

        // Only add if the color is currently in favoriteColorNumbers
        if (widget.favoriteColorNumbers.contains(colorNumber)) {
          debugPrint(
              'Found favorite color: $colorNumber in category $category');
          final colorData = <String, dynamic>{
            ...color,
            'name': color['name'] ?? '',
            'number': colorNumber,
            'value': color['value'],
            'category': category,
          };

          favorites.add(colorData);
          processedNumbers.add(colorNumber);

          // Add to wood favorites if it's from the wood category
          if (category == 'asian' || category == 'ncs') {
            woodFavorites.add(colorData);
            debugPrint('Added to wood favorites: $colorNumber');
          }
        }
      }
    });

    debugPrint('Total favorites found: ${favorites.length}');
    debugPrint('Wood favorites found: ${woodFavorites.length}');

    // Update state with new favorites lists
    if (mounted) {
      setState(() {
        _favoriteColors = favorites;
        _woodFavoriteColors = woodFavorites;
      });
    }
  }

  void _handleFavoriteToggle(String colorNumber) {
    debugPrint('Toggling favorite for: $colorNumber');
    widget.onFavoriteToggle(colorNumber);
    // The didUpdateWidget will handle the update
  }

  Future<void> _handleRefresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Refreshing favorites...');
      // Force a complete rebuild of the favorites list
      _updateFavoriteColors();
      // Add a small delay to ensure the UI updates
      await Future.delayed(const Duration(milliseconds: 100));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildColorGrid(List<Map<String, dynamic>> colors) {
    debugPrint('Building grid with ${colors.length} colors');
    if (colors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No favorite colors yet'),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ColorDetailPage(
                  color: {
                    ...color,
                    'tab': color['category'],
                  },
                  onFavoriteToggle: _handleFavoriteToggle,
                  isFavorite: true,
                  allColors: _allColorsWithWood.map(
                      (key, value) => MapEntry(key, value as List<dynamic>)),
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            color: hexToColor(color['value']),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          color['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${color['number']} - ${color['value']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Colors'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Favorites'),
            Tab(text: 'Wood Colors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _buildColorGrid(_favoriteColors),
          ),
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _buildColorGrid(_woodFavoriteColors),
          ),
        ],
      ),
    );
  }
}
