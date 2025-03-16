import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_detail_page.dart';
import 'favorites_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color Palette',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ColorPalettePage(),
    );
  }
}

class ColorPalettePage extends StatefulWidget {
  const ColorPalettePage({super.key});

  @override
  State<ColorPalettePage> createState() => _ColorPalettePageState();
}

class _ColorPalettePageState extends State<ColorPalettePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> colors = {};
  String searchQuery = '';
  Map<String, List<dynamic>> filteredColors = {};
  Set<String> favoriteColorNumbers = {};
  late SharedPreferences prefs;
  bool isLoading = true;
  late TabController _tabController;
  Map<String, int> _loadedItemsCount = {
    'light': 999999, // Load all for other tabs
    'medium': 999999,
    'dark': 999999,
    'opus': 20, // Initially load only 20 for opus
  };
  final Map<String, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
    loadColorsAndFavorites();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Check if we're switching to the opus tab
      String currentCategory =
          ['light', 'medium', 'dark', 'opus'][_tabController.index];
      if (currentCategory == 'opus') {
        // Reset to only show first 20 items when switching to opus tab
        setState(() {
          _loadedItemsCount['opus'] = 20;
        });
      }
    }
  }

  void _loadMoreItems(String category) {
    setState(() {
      // Load 20 more items
      _loadedItemsCount[category] = (_loadedItemsCount[category] ?? 0) + 20;
    });
  }

  Future<void> loadColorsAndFavorites() async {
    setState(() {
      isLoading = true;
    });

    // Load both colors and favorites concurrently
    await Future.wait([
      _loadColors(),
      _loadFavorites(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadFavorites() async {
    prefs = await SharedPreferences.getInstance();
    favoriteColorNumbers = prefs.getStringList('favorites')?.toSet() ?? {};
  }

  Future<void> toggleFavorite(String colorNumber) async {
    setState(() {
      if (favoriteColorNumbers.contains(colorNumber)) {
        favoriteColorNumbers.remove(colorNumber);
      } else {
        favoriteColorNumbers.add(colorNumber);
      }
    });
    await prefs.setStringList('favorites', favoriteColorNumbers.toList());
  }

  Future<void> _loadColors() async {
    // Use a more efficient JSON parsing approach
    final String jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/colors.json');

    // Parse JSON in an isolate to avoid UI freezes
    final decodedColors = await compute(_parseJson, jsonString);

    // Pre-process colors once during loading
    final processedColors = Map.fromEntries(
      decodedColors.entries.map((entry) => MapEntry(
            entry.key,
            (entry.value as List).cast<dynamic>(),
          )),
    );

    colors = decodedColors;
    filteredColors = processedColors;
  }

  // This runs in a separate isolate
  static Map<String, dynamic> _parseJson(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  void filterColors(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) => MapEntry(
                entry.key,
                (entry.value as List).cast<dynamic>(),
              )),
        );
      } else {
        // Group colors by page number for each category
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) {
            // Filter colors that match the query
            final allCategoryColors = (entry.value as List);
            final filteredCategoryColors = allCategoryColors.where((color) {
              return color['name']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  color['number']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase());
            }).toList();

            // Group filtered colors by page number
            Map<int, List<dynamic>> colorsByPage = {};
            for (var color in filteredCategoryColors) {
              int page = color['page'] ?? 1;
              if (!colorsByPage.containsKey(page)) {
                colorsByPage[page] = [];
              }
              colorsByPage[page]!.add(color);
            }

            // Convert page-grouped colors to a flat list
            List<dynamic> pageGroupedColors = [];
            colorsByPage.forEach((page, colors) {
              pageGroupedColors.addAll(colors);
            });

            return MapEntry(entry.key, pageGroupedColors);
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

    // Store in cache
    _colorCache[hexString] = color;
    return color;
  }

  Widget buildColorList(String category) {
    final categoryColors = filteredColors[category] ?? [];

    // If no colors, return empty container
    if (categoryColors.isEmpty) {
      return const Center(child: Text('No colors found'));
    }

    // For Opus tab, use the special OpusTabView with sub-tabs
    if (category == 'opus') {
      return OpusTabView(
        colors: categoryColors,
        onFavoriteToggle: toggleFavorite,
        favoriteColorNumbers: favoriteColorNumbers,
        hexToColor: hexToColor,
      );
    }

    // For other tabs, use the existing implementation
    // Group colors by page - do this once and cache the result
    Map<int, List<dynamic>> colorsByPage = {};
    for (var color in categoryColors) {
      int page = color['page'] ?? 1;
      if (!colorsByPage.containsKey(page)) {
        colorsByPage[page] = [];
      }
      colorsByPage[page]!.add(color);
    }

    // Sort pages by page number
    List<int> sortedPages = colorsByPage.keys.toList()..sort();

    // Limit the number of items to display for lazy loading
    int itemsToShow = _loadedItemsCount[category] ?? 999999;
    int totalItems = 0;
    List<int> pagesToShow = [];

    for (var page in sortedPages) {
      int pageItemCount = colorsByPage[page]!.length;
      if (totalItems + pageItemCount <= itemsToShow) {
        pagesToShow.add(page);
        totalItems += pageItemCount;
      } else {
        // If we can show at least some items from this page
        if (totalItems < itemsToShow) {
          pagesToShow.add(page);
        }
        break;
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          // User has scrolled to the bottom, load more items
          if (category == 'opus' && totalItems < categoryColors.length) {
            _loadMoreItems(category);
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount:
            pagesToShow.length + (totalItems < categoryColors.length ? 1 : 0),
        itemBuilder: (context, pageIndex) {
          if (pageIndex >= pagesToShow.length) {
            // This is the loading indicator at the bottom
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final pageNumber = pagesToShow[pageIndex];
          final pageColors = colorsByPage[pageNumber]!;

          // For the last page, we might need to limit the number of colors
          List<dynamic> colorsToShow = pageColors;
          if (pageIndex == pagesToShow.length - 1 && totalItems > itemsToShow) {
            int remainingItems = itemsToShow - (totalItems - pageColors.length);
            colorsToShow = pageColors.sublist(0, remainingItems);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  crossAxisCount: 4,
                  childAspectRatio: 0.7,
                ),
                itemCount: colorsToShow.length,
                itemBuilder: (context, colorIndex) {
                  final color = colorsToShow[colorIndex];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ColorDetailPage(
                            color: color,
                            onFavoriteToggle: toggleFavorite,
                            isFavorite:
                                favoriteColorNumbers.contains(color['number']),
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: hexToColor(color['value']),
                      child: Center(
                        child: Text(
                          color['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    List<String> categories = ['light', 'medium', 'dark', 'opus'];
    categories = categories
        .where((category) => filteredColors[category]?.isNotEmpty ?? false)
        .toList();

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Color Palette'),
          actions: [
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesPage(
                      allColors: colors,
                      favoriteColorNumbers: favoriteColorNumbers,
                      onFavoriteToggle: toggleFavorite,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: filterColors,
                    decoration: InputDecoration(
                      hintText: 'Search by name or number',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (categories.isNotEmpty)
                  TabBar(
                    controller: _tabController,
                    tabs: categories
                        .map((category) => Tab(text: category.capitalize()))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : categories.isEmpty
                ? const Center(child: Text('No results found'))
                : TabBarView(
                    controller: _tabController,
                    children: categories.map((category) {
                      return buildColorList(category);
                    }).toList(),
                  ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Add this class to handle sub-tabs for Opus
class OpusTabView extends StatefulWidget {
  final List<dynamic> colors;
  final Function(String) onFavoriteToggle;
  final Set<String> favoriteColorNumbers;
  final Function(String) hexToColor;

  const OpusTabView({
    Key? key,
    required this.colors,
    required this.onFavoriteToggle,
    required this.favoriteColorNumbers,
    required this.hexToColor,
  }) : super(key: key);

  @override
  State<OpusTabView> createState() => _OpusTabViewState();
}

class _OpusTabViewState extends State<OpusTabView>
    with TickerProviderStateMixin {
  late TabController _subTabController;
  Map<String, List<dynamic>> _categorizedColors = {};
  List<String> _categories = ['All'];
  int _loadedItemsCount = 20;
  final String _defaultCategory = 'BB';

  @override
  void initState() {
    super.initState();
    _categorizeColors();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _categorizeColors() {
    // Initialize with "All" category
    _categorizedColors = {'All': widget.colors};

    // Group colors by first two letters of color number
    Map<String, List<dynamic>> tempCategories = {};

    for (var color in widget.colors) {
      String colorNumber = color['number'].toString();
      if (colorNumber.length >= 2) {
        String prefix = colorNumber.substring(0, 2).toUpperCase();

        if (!tempCategories.containsKey(prefix)) {
          tempCategories[prefix] = [];
        }
        tempCategories[prefix]!.add(color);
      }
    }

    // Sort categories and add to the map
    List<String> sortedPrefixes = tempCategories.keys.toList()..sort();
    for (var prefix in sortedPrefixes) {
      _categorizedColors[prefix] = tempCategories[prefix]!;
    }

    // Update categories list
    _categories = ['All', ...sortedPrefixes];

    // Initialize tab controller with the default tab selected
    if (mounted) {
      setState(() {
        _subTabController =
            TabController(length: _categories.length, vsync: this);

        // Set the default tab to BB if it exists
        if (_categories.contains(_defaultCategory)) {
          int defaultIndex = _categories.indexOf(_defaultCategory);
          _subTabController.animateTo(defaultIndex);
        }
      });
    }
  }

  void _loadMoreItems() {
    setState(() {
      _loadedItemsCount += 20;
    });
  }

  Widget _buildColorGrid(List<dynamic> colors) {
    // Group colors by page
    Map<int, List<dynamic>> colorsByPage = {};
    for (var color in colors) {
      int page = color['page'] ?? 1;
      if (!colorsByPage.containsKey(page)) {
        colorsByPage[page] = [];
      }
      colorsByPage[page]!.add(color);
    }

    // Sort pages
    List<int> sortedPages = colorsByPage.keys.toList()..sort();

    // Limit items for lazy loading
    int totalItems = 0;
    List<int> pagesToShow = [];

    for (var page in sortedPages) {
      int pageItemCount = colorsByPage[page]!.length;
      if (totalItems + pageItemCount <= _loadedItemsCount) {
        pagesToShow.add(page);
        totalItems += pageItemCount;
      } else {
        if (totalItems < _loadedItemsCount) {
          pagesToShow.add(page);
        }
        break;
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          if (totalItems < colors.length) {
            _loadMoreItems();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: pagesToShow.length + (totalItems < colors.length ? 1 : 0),
        itemBuilder: (context, pageIndex) {
          if (pageIndex >= pagesToShow.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final pageNumber = pagesToShow[pageIndex];
          final pageColors = colorsByPage[pageNumber]!;

          // For the last page, limit colors if needed
          List<dynamic> colorsToShow = pageColors;
          if (pageIndex == pagesToShow.length - 1 &&
              totalItems > _loadedItemsCount) {
            int remainingItems =
                _loadedItemsCount - (totalItems - pageColors.length);
            colorsToShow = pageColors.sublist(0, remainingItems);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  crossAxisCount: 4,
                  childAspectRatio: 0.7,
                ),
                itemCount: colorsToShow.length,
                itemBuilder: (context, colorIndex) {
                  final color = colorsToShow[colorIndex];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ColorDetailPage(
                            color: color,
                            onFavoriteToggle: widget.onFavoriteToggle,
                            isFavorite: widget.favoriteColorNumbers
                                .contains(color['number']),
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: widget.hexToColor(color['value']),
                      child: Center(
                        child: Text(
                          color['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: _categories.map((category) {
              return _buildColorGrid(_categorizedColors[category] ?? []);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
