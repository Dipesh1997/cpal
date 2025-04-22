import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_detail_page.dart';
import 'favorites_page.dart';
import 'screens/color_picker_page.dart';
import 'screens/drawing_canvas_page.dart';
import 'wood.dart';

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
  late Map<String, List<dynamic>> colors;
  String searchQuery = '';
  Map<String, List<dynamic>> filteredColors = {};
  late SharedPreferences prefs;
  bool isLoading = true;
  late TabController _mainTabController;
  TabController? _asianTabController;
  Set<String> _favoriteColors = {};
  Map<String, int> _loadedItemsCount = {
    'light': 20,
    'medium': 20,
    'dark': 20,
    'opus': 20,
    'SA': 20,
    'SV': 20,
    'ncs': 20,
  };
  final Map<String, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
    loadColorsAndFavorites();
    _mainTabController = TabController(length: 3, vsync: this);
    _mainTabController.addListener(_handleMainTabChange);
    _loadFavorites();
  }

  @override
  void dispose() {
    _mainTabController.removeListener(_handleMainTabChange);
    _mainTabController.dispose();
    _asianTabController?.dispose();
    super.dispose();
  }

  void _handleMainTabChange() {
    if (_mainTabController.indexIsChanging) {
      if (_mainTabController.index == 1) {
        // OPUS tab
        setState(() {
          _loadedItemsCount['opus'] = 20;
        });
      }
    }
  }

  void _loadMoreItems(String category) {
    setState(() {
      _loadedItemsCount[category] = (_loadedItemsCount[category] ?? 0) + 20;
    });
  }

  Future<void> loadColorsAndFavorites() async {
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
      String jsonString =
          await DefaultAssetBundle.of(context).loadString('assets/colors.json');
      setState(() {
        colors = Map<String, List<dynamic>>.from(json.decode(jsonString));
        // Add wood colors to the colors map
        colors['wood'] = WoodColors.colors;
        // Initialize filteredColors with all colors
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) => MapEntry(
                entry.key,
                (entry.value as List).cast<dynamic>(),
              )),
        );
      });
    } catch (e) {
      print('Error loading colors: $e');
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
      print('Error loading favorites: $e');
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
      print('Error toggling favorite: $e');
    }
  }

  bool isFavorite(String colorNumber) {
    return _favoriteColors.contains(colorNumber);
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
        // Keep a copy of all colors for finding similar colors
        Map<String, List<dynamic>> allColors = Map.fromEntries(
          colors.entries.map((entry) => MapEntry(
                entry.key,
                (entry.value as List<dynamic>),
              )),
        );

        // Normalize the search query by removing spaces and special characters
        String normalizedQuery =
            query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

        filteredColors = Map.fromEntries(
          colors.entries.map((entry) {
            final allCategoryColors = (entry.value as List);
            final filteredCategoryColors = allCategoryColors.where((color) {
              try {
                if (entry.key.toLowerCase() == 'ncs') {
                  // Safely get the number and value, providing defaults if null
                  String number = (color['number'] ?? '').toString();
                  String value = (color['value'] ?? '').toString();

                  // Normalize the number for comparison
                  String normalizedNumber =
                      number.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                  String normalizedValue = value.toLowerCase();

                  return normalizedNumber.contains(normalizedQuery) ||
                      normalizedValue.contains(query.toLowerCase()) ||
                      // Also check original number for exact matches with spaces/special chars
                      number.toLowerCase().contains(query.toLowerCase());
                } else {
                  // For other colors, safely check name and number
                  String name = (color['name'] ?? '').toString();
                  String number = (color['number'] ?? '').toString();

                  return name.toLowerCase().contains(query.toLowerCase()) ||
                      number.toLowerCase().contains(query.toLowerCase());
                }
              } catch (e) {
                print('Error filtering color: $e');
                return false;
              }
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

    // Store in cache
    _colorCache[hexString] = color;
    return color;
  }

  Widget _buildColorGrid(String category) {
    try {
      final categoryColors = filteredColors[category] ?? [];

      // If no colors, return empty container
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

      // Group colors by page number
      Map<int, List<dynamic>> colorsByPage = {};
      for (var color in categoryColors) {
        try {
          int page = int.tryParse(color['page']?.toString() ?? '206') ?? 206;
          if (!colorsByPage.containsKey(page)) {
            colorsByPage[page] = [];
          }
          colorsByPage[page]!.add(color);
        } catch (e) {
          debugPrint('Error processing page number: $e');
          // Add to page 206 if there's an error
          if (!colorsByPage.containsKey(206)) {
            colorsByPage[206] = [];
          }
          colorsByPage[206]!.add(color);
        }
      }

      // Sort pages by page number
      List<int> sortedPages = colorsByPage.keys.toList()..sort();

      return SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: sortedPages.length,
          itemBuilder: (context, pageIndex) {
            try {
              if (pageIndex >= sortedPages.length) {
                return const SizedBox.shrink();
              }

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
                      try {
                        if (index >= pageColors.length) {
                          return const SizedBox.shrink();
                        }

                        var color = pageColors[index];
                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              try {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ColorDetailPage(
                                      color: {
                                        ...color,
                                        'tab': category,
                                      },
                                      onFavoriteToggle: toggleFavorite,
                                      isFavorite: isFavorite(color['number']),
                                      allColors: colors,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                debugPrint(
                                    'Error navigating to color detail: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Error loading color details'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
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
                      } catch (e) {
                        debugPrint('Error building color card: $e');
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              );
            } catch (e) {
              debugPrint('Error building page $pageIndex: $e');
              return const SizedBox.shrink();
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error in color grid: $e');
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error loading colors. Please try again.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildNCSColorGrid(String category) {
    try {
      List<dynamic> categoryColors = filteredColors[category] ?? [];
      if (searchQuery.isNotEmpty) {
        try {
          categoryColors = categoryColors.where((color) {
            try {
              // Safely get the number and value, providing defaults if null
              String number = (color['number'] ?? '').toString();
              String value = (color['value'] ?? '').toString();

              // Normalize both the search query and the color number
              String normalizedQuery =
                  searchQuery.replaceAll(RegExp(r'[^a-z0-9]'), '');
              String normalizedNumber =
                  number.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
              String normalizedValue = value.toLowerCase();

              return normalizedNumber.contains(normalizedQuery) ||
                  normalizedValue.contains(searchQuery) ||
                  // Also check original number for exact matches with spaces/special chars
                  number.toLowerCase().contains(searchQuery);
            } catch (e) {
              debugPrint('Error filtering NCS color: $e');
              return false;
            }
          }).toList();
        } catch (e) {
          debugPrint('Error filtering NCS colors: $e');
          categoryColors = [];
        }
      }

      // If no colors, return empty container
      if (categoryColors.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No NCS colors found matching your search',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // Group colors by page number
      Map<int, List<dynamic>> colorsByPage = {};
      for (var color in categoryColors) {
        try {
          int page = int.tryParse(color['page']?.toString() ?? '300') ?? 300;
          if (!colorsByPage.containsKey(page)) {
            colorsByPage[page] = [];
          }
          colorsByPage[page]!.add(color);
        } catch (e) {
          debugPrint('Error processing page number: $e');
          // Add to page 300 if there's an error
          if (!colorsByPage.containsKey(300)) {
            colorsByPage[300] = [];
          }
          colorsByPage[300]!.add(color);
        }
      }

      // Sort pages by page number
      List<int> sortedPages = colorsByPage.keys.toList()..sort();

      return SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: sortedPages.length,
          itemBuilder: (context, pageIndex) {
            try {
              if (pageIndex >= sortedPages.length) {
                return const SizedBox.shrink();
              }

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
                      try {
                        if (index >= pageColors.length) {
                          return const SizedBox.shrink();
                        }

                        var color = pageColors[index];
                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              try {
                                if (color['value'] == null ||
                                    color['page'] == null ||
                                    color['position'] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Color details not available yet'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ColorDetailPage(
                                      color: {
                                        ...color,
                                        'tab': category,
                                      },
                                      onFavoriteToggle: toggleFavorite,
                                      isFavorite: isFavorite(color['number']),
                                      allColors: filteredColors,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                debugPrint(
                                    'Error navigating to color detail: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Error loading color details'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color['value'] != null
                                            ? hexToColor(color['value'])
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    color['number'] ?? 'Coming Soon',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (color['value'] == null ||
                                      color['page'] == null ||
                                      color['position'] == null)
                                    const Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error building color card: $e');
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              );
            } catch (e) {
              debugPrint('Error building page $pageIndex: $e');
              return const SizedBox.shrink();
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error in NCS color grid: $e');
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error loading NCS colors. Please try again.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildAsianTabView() {
    try {
      List<String> asianTabs = ['light', 'medium', 'dark', 'SA', 'SV', 'wood'];
      List<String> visibleTabs = [];

      // Only show tabs that have search results
      for (var tab in asianTabs) {
        try {
          if ((filteredColors[tab] ?? []).isNotEmpty) {
            visibleTabs.add(tab);
          }
        } catch (e) {
          debugPrint('Error processing tab $tab: $e');
          continue;
        }
      }

      // If no visible tabs, return empty container
      if (visibleTabs.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No results found in Asian color sets',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return DefaultTabController(
        length: visibleTabs.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: visibleTabs
                  .map((tab) => Tab(text: tab.toUpperCase()))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                children: visibleTabs.map((tab) {
                  try {
                    return _buildColorGrid(tab);
                  } catch (e) {
                    debugPrint('Error building color grid for tab $tab: $e');
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading colors for this category',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error in Asian tab view: $e');
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Something went wrong while loading Asian colors. Please try again.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which main tabs have results
    List<Widget> visibleTabs = [];
    List<Widget> visibleTabViews = [];

    // Check Asian tabs
    bool hasAsianResults = false;
    List<String> asianTabs = ['light', 'medium', 'dark', 'SA', 'SV'];
    for (var tab in asianTabs) {
      if ((filteredColors[tab] ?? []).isNotEmpty) {
        hasAsianResults = true;
        break;
      }
    }
    if (hasAsianResults) {
      visibleTabs.add(const Tab(text: 'ASIAN'));
      visibleTabViews.add(_buildAsianTabView());
    }

    // Check Opus tab
    if ((filteredColors['opus'] ?? []).isNotEmpty) {
      visibleTabs.add(const Tab(text: 'OPUS'));
      visibleTabViews.add(
        OpusTabView(
          colors: filteredColors['opus'] ?? [],
          onFavoriteToggle: toggleFavorite,
          favoriteColorNumbers: _favoriteColors,
          filteredColors: filteredColors,
          hexToColor: hexToColor,
        ),
      );
    }

    // Check NCS tab
    if ((filteredColors['ncs'] ?? []).isNotEmpty) {
      visibleTabs.add(const Tab(text: 'NCS'));
      visibleTabViews.add(_buildNCSColorGrid('ncs'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palette'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DrawingCanvasPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ColorPickerPage(
                    initialColors: colors,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesPage(
                    allColors: filteredColors,
                    onFavoriteToggle: toggleFavorite,
                    favoriteColorNumbers: _favoriteColors,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search colors by name or number...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                  filterColors(value);
                });
              },
            ),
          ),
          if (visibleTabs.isNotEmpty) ...[
            TabBar(
              controller: _mainTabController,
              tabs: visibleTabs,
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _mainTabController,
                      children: visibleTabViews,
                    ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'No results found',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
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
  final Map<String, List<dynamic>> filteredColors;
  final Function(String) hexToColor;

  const OpusTabView({
    Key? key,
    required this.colors,
    required this.onFavoriteToggle,
    required this.favoriteColorNumbers,
    required this.filteredColors,
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

          // For the last page, we might need to limit the number of colors
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
                            color: {
                              ...color,
                              'tab': 'opus',
                            },
                            onFavoriteToggle: widget.onFavoriteToggle,
                            isFavorite: widget.favoriteColorNumbers
                                .contains(color['number']),
                            allColors: widget.filteredColors,
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
