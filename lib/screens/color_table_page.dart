import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../color_detail_page.dart';
import '../woodcolors.dart';
import '../ncscolors.dart';
import '../main.dart';
import 'dart:math' as math;

class ColorTablePage extends StatefulWidget {
  final Function(String) onFavoriteToggle;
  final Set<String> favoriteColorNumbers;

  const ColorTablePage({
    super.key,
    required this.onFavoriteToggle,
    required this.favoriteColorNumbers,
  });

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
  bool isLoading = true;

  late TabController _tabController;
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
    loadColors();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadColors() async {
    setState(() {
      isLoading = true;
    });

    await _loadColors();

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

                return name.contains(normalizedQuery) ||
                    number.contains(normalizedQuery) ||
                    value.contains(normalizedQuery) ||
                    cleanNumber.contains(normalizedQuery) ||
                    withHyphen.contains(normalizedQuery);
              }

              return name.contains(normalizedQuery) ||
                  number.contains(normalizedQuery) ||
                  value.contains(normalizedQuery);
            }).toList();

            return MapEntry(entry.key, filteredCategoryColors);
          }),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Table'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ASIAN'),
            Tab(text: 'NCS'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterColors,
              decoration: const InputDecoration(
                labelText: 'Search Colors',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
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

  Widget _buildColorGrid(String category) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final categoryColors = filteredColors[category] ?? [];
    if (categoryColors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No colors found in this category'),
        ),
      );
    }

    // Group colors by page
    Map<int, List<dynamic>> colorsByPage = {};
    for (var color in categoryColors) {
      int page = int.tryParse(color['page']?.toString() ?? '1') ?? 1;
      if (!colorsByPage.containsKey(page)) {
        colorsByPage[page] = [];
      }
      colorsByPage[page]!.add(color);
    }

    // Sort pages
    List<int> sortedPages = colorsByPage.keys.toList()..sort();

    return SingleChildScrollView(
      child: ListView.builder(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              onFavoriteToggle: widget.onFavoriteToggle,
                              isFavorite: widget.favoriteColorNumbers
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
    );
  }
}
