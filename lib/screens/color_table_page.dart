import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../color_detail_page.dart';
import '../woodcolors.dart';
import '../ncscolors.dart';
import '../main.dart';
import 'dart:math' as math;

class ColorTablePage extends StatefulWidget {
  const ColorTablePage({super.key});

  @override
  State<ColorTablePage> createState() => _ColorTablePageState();

  // Static method to get preloaded colors
  static Map<String, List<dynamic>>? getPreloadedTableColors() {
    try {
      return {
        'asian': WoodColors.colors,
        'ncs': NcsColors.colors,
      };
    } catch (e) {
      debugPrint('Error getting preloaded colors: $e');
      return null;
    }
  }
}

class _ColorTablePageState extends State<ColorTablePage>
    with TickerProviderStateMixin {
  late Map<String, List<dynamic>> colors;
  String searchQuery = '';
  Map<String, List<dynamic>> filteredColors = {};
  late SharedPreferences prefs;
  bool isLoading = true;

  late TabController _tabController;
  Set<String> _favoriteColors = {};
  final Map<String, Color> _colorCache = {};

  // Lazy loading configuration
  Map<String, int> _loadedItemsCount = {
    'asian': 20,
    'ncs': 20,
  };
  final Map<String, List<dynamic>> _cachedFilteredColors = {};
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    loadColorsAndFavorites();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadColorsAndFavorites() async {
    setState(() {
      isLoading = true;
    });

    await _loadColors();
    await _loadFavorites();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadColors() async {
    try {
      // Try to get preloaded colors
      final preloadedColors = ColorTablePage.getPreloadedTableColors();

      if (preloadedColors != null) {
        debugPrint('✅ Using preloaded colors for ColorTablePage');
        setState(() {
          colors = preloadedColors;
          filteredColors = Map.fromEntries(
            colors.entries.map((entry) => MapEntry(
                  entry.key,
                  (entry.value as List).cast<dynamic>(),
                )),
          );
        });
      } else {
        debugPrint('⚠️ Preloaded colors not available, loading directly');
        setState(() {
          colors = {
            'asian': WoodColors.colors,
            'ncs': NcsColors.colors,
          };
          filteredColors = Map.fromEntries(
            colors.entries.map((entry) => MapEntry(
                  entry.key,
                  (entry.value as List).cast<dynamic>(),
                )),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading colors: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];
      setState(() {
        _favoriteColors = favorites.toSet();
      });
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String colorNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];
      if (favorites.contains(colorNumber)) {
        favorites.remove(colorNumber);
      } else {
        favorites.add(colorNumber);
      }
      await prefs.setStringList('favoriteColors', favorites);
      setState(() {
        _favoriteColors = favorites.toSet();
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  void filterColors(String query) {
    setState(() {
      searchQuery = query;
      debugPrint('🔍 SEARCH QUERY: "$query"');

      if (query.isEmpty) {
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) => MapEntry(
                entry.key,
                (entry.value as List).cast<dynamic>(),
              )),
        );
      } else {
        String normalizedQuery = query.toLowerCase().trim();
        debugPrint('🔍 NORMALIZED QUERY: "$normalizedQuery"');

        filteredColors = Map.fromEntries(
          colors.entries.map((entry) {
            final allCategoryColors = (entry.value as List);
            final filteredCategoryColors = allCategoryColors.where((color) {
              String name = (color['name'] ?? '').toString().toLowerCase();
              String number = (color['number'] ?? '').toString().toLowerCase();
              String value = (color['value'] ?? '').toString().toLowerCase();

              // Special handling for NCS colors
              if (entry.key == 'ncs') {
                // Create variations of the color number
                String cleanNumber = number.replaceAll('-', '');
                String withHyphen = number.contains('-')
                    ? number
                    : number.replaceAll(RegExp(r'(\d{4})([A-Z])'), r'$1-$2');

                // Check if the query matches any variation
                bool numberMatch = number.contains(normalizedQuery) ||
                    cleanNumber.contains(normalizedQuery) ||
                    withHyphen.contains(normalizedQuery);

                // For specific NCS patterns like "0300-N" or "4502-R50B"
                if (RegExp(r'^\d{4}-[A-Z](\d{2}[A-Z])?$')
                    .hasMatch(normalizedQuery)) {
                  String queryClean = normalizedQuery.replaceAll('-', '');
                  String colorClean = number.replaceAll('-', '');
                  numberMatch = numberMatch || colorClean.contains(queryClean);
                }

                debugPrint(
                    '🎨 NCS Color: $number, Clean: $cleanNumber, With Hyphen: $withHyphen');
                debugPrint('🔍 Match found: $numberMatch');

                return name.contains(normalizedQuery) ||
                    numberMatch ||
                    value.contains(normalizedQuery);
              }

              // Standard search for other categories
              return name.contains(normalizedQuery) ||
                  number.contains(normalizedQuery) ||
                  value.contains(normalizedQuery);
            }).toList();

            debugPrint(
                '📊 ${entry.key} results: ${filteredCategoryColors.length}');
            return MapEntry(entry.key, filteredCategoryColors);
          }),
        );
      }

      // Reset loaded items count when search query changes
      _loadedItemsCount = {
        'asian': 20,
        'ncs': 20,
      };

      // Cache the filtered colors for lazy loading
      _cachedFilteredColors.clear();
      for (var entry in filteredColors.entries) {
        _cachedFilteredColors[entry.key] = List.from(entry.value);
      }
    });
  }

  Color hexToColor(String hexString) {
    if (_colorCache.containsKey(hexString)) {
      return _colorCache[hexString]!;
    }

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    final color = Color(int.parse(buffer.toString(), radix: 16));

    _colorCache[hexString] = color;
    return color;
  }

  /// Loads more items for a specific category
  void _loadMoreItems(String category) {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _loadedItemsCount[category] = (_loadedItemsCount[category] ?? 0) + 20;
      _isLoadingMore = false;
    });
  }

  /// Gets the currently loaded items for a category
  List<dynamic> _getLoadedItems(String category) {
    final allItems =
        _cachedFilteredColors[category] ?? filteredColors[category] ?? [];
    final loadedCount = _loadedItemsCount[category] ?? 20;

    if (allItems.length <= loadedCount) {
      return allItems;
    }

    return allItems.sublist(0, loadedCount);
  }

  Widget _buildColorGrid(String category) {
    final categoryColors = _getLoadedItems(category);
    final allCategoryColors = filteredColors[category] ?? [];
    final hasMoreItems = categoryColors.length < allCategoryColors.length;

    if (categoryColors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No colors found in this category',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Map<int, List<dynamic>> colorsByPage = {};
    for (var color in categoryColors) {
      int page = int.tryParse(color['page']?.toString() ?? '1') ?? 1;
      if (!colorsByPage.containsKey(page)) {
        colorsByPage[page] = [];
      }
      colorsByPage[page]!.add(color);
    }

    List<int> sortedPages = colorsByPage.keys.toList()..sort();

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          if (hasMoreItems) {
            _loadMoreItems(category);
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: sortedPages.length,
              itemBuilder: (context, pageIndex) {
                final pageNumber = sortedPages[pageIndex];
                final pageColors = colorsByPage[pageNumber]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Page $pageNumber',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: pageColors.length,
                      itemBuilder: (context, index) {
                        var color = pageColors[index];
                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ColorDetailPage(
                                    color: {
                                      ...color,
                                      'tab': category,
                                    },
                                    onFavoriteToggle: toggleFavorite,
                                    isFavorite: _favoriteColors
                                        .contains(color['number']),
                                    allColors: colors,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: hexToColor(color['value']),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    color['number'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            if (hasMoreItems)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wood'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search colors by name, number, or value...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: filterColors,
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'ASIAN'),
              Tab(text: 'NCS'),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildColorGrid('asian'),
                      _buildColorGrid('ncs'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
