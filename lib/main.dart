import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_detail_page.dart';
import 'favorites_page.dart';
import 'screens/color_picker_page.dart';
import 'screens/drawing_canvas_page.dart';
import 'screens/color_table_page.dart';
import 'lightcolors.dart';
import 'mediumcolors.dart';
import 'darkcolors.dart';
import 'sacolors.dart';
import 'svcolors.dart';
import 'opuscolors.dart';
import 'woodcolors.dart';
import 'ncscolors.dart';
import 'dart:math' as math;
import 'services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';

// Main entry point for the Color Palette application
// Initializes the app and sets up required services
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  runApp(const MyApp());
}

/// Root widget of the application
/// Sets up the MaterialApp with theme and initial route
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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _searchText = '';
  int _currentIndex = 0;
  final String _targetText = 'l136';
  bool _isSearching = true;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Simulate typing animation
    Future.delayed(const Duration(milliseconds: 500), () {
      _startTypingAnimation();
    });

    // Show results after typing
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _showResults = true;
      });
    });

    // Navigate to main screen after animation
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ColorPalettePage()),
      );
    });
  }

  void _startTypingAnimation() {
    Future.doWhile(() async {
      if (_currentIndex < _targetText.length) {
        setState(() {
          _searchText += _targetText[_currentIndex];
          _currentIndex++;
        });
        await Future.delayed(const Duration(milliseconds: 200));
        return true;
      } else {
        setState(() {
          _isSearching = false;
        });
        return false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Logo at top center
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Image.asset(
                  'assets/icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            const Spacer(),
            // Search Box
            Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                  Expanded(
                    child: Text(
                      _searchText,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search Results
            if (_showResults)
              Container(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Page 8',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFFF1E8D8), // Updated to #F1E8D8
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'L136',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // App Title
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'Color Palette',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Main page of the Color Palette application
/// Handles color display, searching, filtering, and tab management
class ColorPalettePage extends StatefulWidget {
  const ColorPalettePage({super.key});

  @override
  State<ColorPalettePage> createState() => _ColorPalettePageState();
}

/// State class for ColorPalettePage
/// Manages the complex state of the color palette including:
/// - Color data loading and caching
/// - Search functionality
/// - Tab management
/// - Favorites system
class _ColorPalettePageState extends State<ColorPalettePage>
    with TickerProviderStateMixin {
  // Color data and search state
  late Map<String, List<dynamic>> colors;
  String searchQuery = '';
  Map<String, List<dynamic>> filteredColors = {};
  late SharedPreferences prefs;
  bool isLoading = true;

  // Tab controllers
  late TabController _mainTabController;
  TabController? _asianTabController;

  // Favorites management
  Set<String> _favoriteColors = {};

  // Lazy loading configuration
  Map<String, int> _loadedItemsCount = {
    'light': 20,
    'medium': 20,
    'dark': 20,
    'opus': 20,
    'SA': 20,
    'SV': 20,
  };

  // Cache management
  final Map<String, Color> _colorCache = {};
  final Map<int, Widget> _tabViewCache = {};
  final Map<String, Widget> _asianTabViewCache = {};
  bool _isPreloading = false;
  int _currentTabIndex = 0;

  // Preloaded colors for ColorTablePage
  static Map<String, List<dynamic>>? _preloadedTableColors;

  RewardedAd? _rewardedAd;
  bool _isRewarded = false;
  bool _isSpinning = false;
  double _rotation = 0;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  bool _isAdLoading = false;
  int _adLoadAttempts = 0;
  static const int maxAdLoadAttempts = 5;
  DateTime? _lastAdLoadTime;

  /// Initializes the state
  /// Sets up controllers, loads colors and favorites
  @override
  void initState() {
    super.initState();
    loadColorsAndFavorites();
    _mainTabController = TabController(length: 1, vsync: this);
    _mainTabController.addListener(_handleMainTabChange);
    _loadFavorites();
    _preloadTableColors();

    // Initialize spin wheel animation
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _spinAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi * 5,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOut,
    ));

    _spinController.addListener(() {
      setState(() {
        _rotation = _spinAnimation.value;
      });
    });

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
        _showRewardDialog();
      }
    });

    // Initialize Mobile Ads SDK
    MobileAds.instance.initialize().then((initializationStatus) {
      // Load rewarded ad after SDK initialization
      _loadRewardedAd();
    });
  }

  /// Cleans up resources when the widget is disposed
  /// Removes listeners and clears caches
  @override
  void dispose() {
    _mainTabController.removeListener(_handleMainTabChange);
    _mainTabController.dispose();
    _asianTabController?.dispose();
    _tabViewCache.clear();
    _asianTabViewCache.clear();
    _spinController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  /// Handles tab changes in the main tab controller
  /// Clears caches when switching tabs to ensure fresh data
  void _handleMainTabChange() {
    if (_mainTabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _mainTabController.index;
        _tabViewCache.clear();
        _asianTabViewCache.clear();
      });
    }
  }

  /// Preloads all tab views to improve performance
  /// Caches Asian and Opus tab views
  Future<void> _preloadTabViews() async {
    if (_isPreloading) return;
    _isPreloading = true;

    // Preload Asian tab views
    List<String> asianTabs = ['light', 'medium', 'dark', 'SA', 'SV'];
    for (var tab in asianTabs) {
      if ((filteredColors[tab] ?? []).isNotEmpty) {
        _asianTabViewCache[tab] = _buildColorGrid(tab);
      }
    }

    // Preload Opus tab view
    if ((filteredColors['opus'] ?? []).isNotEmpty) {
      _tabViewCache[1] = OpusTabView(
        colors: filteredColors['opus'] ?? [],
        onFavoriteToggle: toggleFavorite,
        favoriteColorNumbers: _favoriteColors,
        filteredColors: filteredColors,
        allColors: colors,
        hexToColor: hexToColor,
      );
    }

    _isPreloading = false;
  }

  /// Implements lazy loading functionality
  /// Loads more items for a specific category when needed
  void _loadMoreItems(String category) {
    setState(() {
      _loadedItemsCount[category] = (_loadedItemsCount[category] ?? 0) + 20;
    });
  }

  /// Loads both colors and favorites data
  /// Initializes the app's data and preloads views
  Future<void> loadColorsAndFavorites() async {
    setState(() {
      isLoading = true;
    });

    await _loadColors();
    await _preloadTabViews();

    setState(() {
      isLoading = false;
    });
  }

  /// Loads color data from all color categories
  /// Initializes both colors and filteredColors maps
  Future<void> _loadColors() async {
    try {
      setState(() {
        colors = {
          'light': LightColors.colors,
          'medium': MediumColors.colors,
          'dark': DarkColors.colors,
          'SA': SaColors.colors,
          'SV': SvColors.colors,
          'opus': OpusColors.colors,
        };
        // Initialize filteredColors with all colors
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) => MapEntry(
                entry.key,
                (entry.value as List).cast<dynamic>(),
              )),
        );
      });
    } catch (e) {
      // Error loading colors
    }
  }

  /// Loads favorite colors from SharedPreferences
  /// Initializes the _favoriteColors set with saved favorites
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];
      setState(() {
        _favoriteColors = favorites.toSet();
      });
    } catch (e) {
      // Error loading favorites
    }
  }

  /// Toggles a color's favorite status
  /// Saves the updated favorites list to SharedPreferences
  /// @param colorNumber The unique identifier of the color to toggle
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
      // Error toggling favorite
    }
  }

  /// Checks if a color is marked as favorite
  /// @param colorNumber The unique identifier of the color to check
  /// @return bool True if the color is in favorites
  bool isFavorite(String colorNumber) {
    return _favoriteColors.contains(colorNumber);
  }

  /// Filters colors based on search query
  /// Updates filteredColors map with matching results
  /// @param query The search string to filter colors by
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

        // Normalize the search query
        String normalizedQuery = query.toLowerCase().trim();

        // Standard filtering approach for all tabs
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) {
            final allCategoryColors = (entry.value as List);

            final filteredCategoryColors = allCategoryColors.where((color) {
              try {
                String name = (color['name'] ?? '').toString();
                String number = (color['number'] ?? '').toString();
                String value = (color['value'] ?? '').toString();

                bool nameMatch = name.toLowerCase().contains(normalizedQuery);
                bool numberMatch =
                    number.toLowerCase().contains(normalizedQuery);
                bool valueMatch = value.toLowerCase().contains(normalizedQuery);

                bool isMatch = nameMatch || numberMatch || valueMatch;

                return isMatch;
              } catch (e) {
                return false;
              }
            }).toList();

            return MapEntry(entry.key, filteredCategoryColors);
          }),
        );
      }
    });

    // Clear the tab view cache when search query changes
    _tabViewCache.clear();
    _asianTabViewCache.clear();

    // Force rebuild of the current tab view
    if (mounted) {
      setState(() {
        // Update the current tab index to force a rebuild
        _currentTabIndex = _mainTabController.index;
      });
    }
  }

  /// Converts a hex color string to a Color object
  /// Uses caching to improve performance
  /// @param hexString The hex color code to convert
  /// @return Color The corresponding Flutter Color object
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

  /// Builds a color grid for a specific category
  /// Organizes colors by page and displays them in a grid layout
  /// @param category The category of colors to display
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
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              );
            } catch (e) {
              return const SizedBox.shrink();
            }
          },
        ),
      );
    } catch (e) {
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

  /// Builds the Asian tab view with sub-tabs
  /// Handles visibility of Asian color categories based on search results
  Widget _buildAsianTabView() {
    try {
      List<String> asianTabs = ['light', 'medium', 'dark', 'SA', 'SV'];
      List<String> visibleTabs = [];

      // Only show tabs that have search results
      for (var tab in asianTabs) {
        if ((filteredColors[tab] ?? []).isNotEmpty) {
          visibleTabs.add(tab);
        }
      }

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
                  // Always build fresh grid for search results
                  return _buildColorGrid(tab);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
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

  /// Gets or creates a cached tab view for the given index
  /// Handles search results differently by always building fresh views
  /// @param index The tab index to get the view for
  Widget _getCachedTabView(int index) {
    // Always build fresh views for search results
    if (searchQuery.isNotEmpty) {
      switch (index) {
        case 0:
          return _buildAsianTabView();
        case 1:
          return OpusTabView(
            key: ValueKey(
                'opus_${searchQuery}_${DateTime.now().millisecondsSinceEpoch}'),
            colors: filteredColors['opus'] ?? [],
            onFavoriteToggle: toggleFavorite,
            favoriteColorNumbers: _favoriteColors,
            filteredColors: filteredColors,
            allColors: colors,
            hexToColor: hexToColor,
          );
      }
    }

    // For non-search views, use cache
    if (!_tabViewCache.containsKey(index)) {
      switch (index) {
        case 0:
          _tabViewCache[index] = _buildAsianTabView();
          break;
        case 1:
          _tabViewCache[index] = OpusTabView(
            colors: filteredColors['opus'] ?? [],
            onFavoriteToggle: toggleFavorite,
            favoriteColorNumbers: _favoriteColors,
            filteredColors: filteredColors,
            allColors: colors,
            hexToColor: hexToColor,
          );
          break;
      }
    }
    return _tabViewCache[index]!;
  }

  /// Main build method for the ColorPalettePage
  /// Sets up the app bar, search box, and tab views
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
    }

    // Check Opus tab - only show if there are Opus results
    if ((filteredColors['opus'] ?? []).isNotEmpty) {
      visibleTabs.add(const Tab(text: 'OPUS'));
    }

    // Update tab controller length if needed
    if (_mainTabController.length != visibleTabs.length) {
      _mainTabController.removeListener(_handleMainTabChange);
      _mainTabController.dispose();
      _mainTabController =
          TabController(length: visibleTabs.length, vsync: this);
      _mainTabController.addListener(_handleMainTabChange);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colors'),
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AboutPage(),
              ),
            );
          },
        ),
        actions: [
          // Spin wheel button
          IconButton(
            icon: Transform.rotate(
              angle: _rotation,
              child: const Icon(Icons.casino),
            ),
            onPressed: _isSpinning ? null : _startSpin,
          ),
          IconButton(
            icon: const Icon(Icons.chair_alt_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ColorTablePage(),
                ),
              );
            },
          ),
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                  'Check out this amazing Color Palette app! https://play.google.com/store/apps/details?id=com.color.paletteasian');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search colors by name, number, or value...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filterColors(value);
                      });
                    },
                  ),
                ),
              ],
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
                      children: List.generate(visibleTabs.length, (index) {
                        // Map the visible tabs to their corresponding views
                        if (index == 0 && hasAsianResults) {
                          return _buildAsianTabView();
                        } else if ((index == 0 && !hasAsianResults) ||
                            (index == 1 && hasAsianResults)) {
                          return OpusTabView(
                            key: ValueKey(
                                'opus_${searchQuery}_${DateTime.now().millisecondsSinceEpoch}'),
                            colors: filteredColors['opus'] ?? [],
                            onFavoriteToggle: toggleFavorite,
                            favoriteColorNumbers: _favoriteColors,
                            filteredColors: filteredColors,
                            allColors: colors,
                            hexToColor: hexToColor,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
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

  /// Preloads colors for the ColorTablePage in the background
  Future<void> _preloadTableColors() async {
    if (_preloadedTableColors != null) return;

    try {
      _preloadedTableColors = {
        'asian': WoodColors.colors,
        'ncs': NcsColors.colors,
      };
    } catch (e) {
      // Error preloading colors for ColorTablePage
    }
  }

  /// Gets the preloaded colors for ColorTablePage
  static Map<String, List<dynamic>>? getPreloadedTableColors() {
    return _preloadedTableColors;
  }

  void _loadRewardedAd() {
    if (_isAdLoading) return;

    // Check if we should reset the attempt counter
    if (_lastAdLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastAdLoadTime!);
      if (timeSinceLastLoad > const Duration(minutes: 5)) {
        _adLoadAttempts = 0;
      }
    }

    if (_adLoadAttempts >= maxAdLoadAttempts) {
      // Reset attempts after 5 minutes
      if (_lastAdLoadTime != null) {
        final timeSinceLastLoad = DateTime.now().difference(_lastAdLoadTime!);
        if (timeSinceLastLoad > const Duration(minutes: 5)) {
          _adLoadAttempts = 0;
        } else {
          return;
        }
      }
    }

    setState(() {
      _isAdLoading = true;
      _adLoadAttempts++;
      _lastAdLoadTime = DateTime.now();
    });

    RewardedAd.load(
      adUnitId: 'ca-app-pub-6710120263757804/7764431600',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
            _adLoadAttempts = 0;
          });

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Ad failed to show: $error');
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Ad failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isAdLoading = false;
          });

          if (_adLoadAttempts < maxAdLoadAttempts) {
            // Exponential backoff for retries
            final delay = Duration(seconds: math.min(1 << _adLoadAttempts, 30));
            Future.delayed(delay, () {
              if (mounted) {
                _loadRewardedAd();
              }
            });
          }
        },
      ),
    );
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: const Text('Free color saving has been enabled!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startSpin() {
    if (_isSpinning) return;

    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          setState(() {
            _isRewarded = true;
            _isSpinning = true;
          });
          _spinController.forward(from: 0);
        },
      );
    } else {
      if (_isAdLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait while we prepare your reward...'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if we should reset the attempt counter
      if (_lastAdLoadTime != null) {
        final timeSinceLastLoad = DateTime.now().difference(_lastAdLoadTime!);
        if (timeSinceLastLoad > const Duration(minutes: 5)) {
          _adLoadAttempts = 0;
        }
      }

      if (_adLoadAttempts >= maxAdLoadAttempts) {
        final timeSinceLastLoad = _lastAdLoadTime != null
            ? DateTime.now().difference(_lastAdLoadTime!)
            : const Duration(minutes: 6);

        if (timeSinceLastLoad > const Duration(minutes: 5)) {
          _adLoadAttempts = 0;
          _loadRewardedAd();
        } else {
          final minutesLeft = 5 - timeSinceLastLoad.inMinutes;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please try again in $minutesLeft minutes'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Preparing your reward...'),
            ],
          ),
        ),
      );

      // Try to load ad again
      _loadRewardedAd();

      // Close dialog after 3 seconds if ad still not ready
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          if (_rewardedAd == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please try again in a moment'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      });
    }
  }
}

/// Extension to add string capitalization functionality
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Widget for displaying Opus colors in a grid
/// Handles color organization, filtering, and lazy loading
class OpusTabView extends StatefulWidget {
  final List<dynamic> colors;
  final Function(String) onFavoriteToggle;
  final Set<String> favoriteColorNumbers;
  final Map<String, List<dynamic>> filteredColors;
  final Map<String, List<dynamic>> allColors;
  final Function(String) hexToColor;

  const OpusTabView({
    Key? key,
    required this.colors,
    required this.onFavoriteToggle,
    required this.favoriteColorNumbers,
    required this.filteredColors,
    required this.allColors,
    required this.hexToColor,
  }) : super(key: key);

  @override
  State<OpusTabView> createState() => _OpusTabViewState();
}

/// State class for OpusTabView
/// Manages the display and organization of Opus colors
class _OpusTabViewState extends State<OpusTabView>
    with TickerProviderStateMixin {
  late TabController _subTabController;
  Map<String, List<dynamic>> _categorizedColors = {};
  List<String> _categories = ['All'];
  int _loadedItemsCount = 20;
  final String _defaultCategory = 'WW';
  final Map<int, Widget> _pageCache = {};

  /// Initializes the state and categorizes colors
  @override
  void initState() {
    super.initState();
    _categorizeColors();
  }

  /// Cleans up resources when the widget is disposed
  @override
  void dispose() {
    _subTabController.dispose();
    _pageCache.clear();
    super.dispose();
  }

  /// Organizes colors into categories based on their number prefix
  /// Sets up the tab controller for category navigation
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

    // Sort categories by the minimum page number in each category
    List<String> sortedPrefixes = tempCategories.keys.toList();
    sortedPrefixes.sort((a, b) {
      int minPageA = tempCategories[a]!.fold<int>(
          double.maxFinite.toInt(),
          (min, color) =>
              math.min(min, color['page'] ?? double.maxFinite.toInt()));
      int minPageB = tempCategories[b]!.fold<int>(
          double.maxFinite.toInt(),
          (min, color) =>
              math.min(min, color['page'] ?? double.maxFinite.toInt()));
      return minPageA.compareTo(minPageB);
    });

    // Add sorted categories to the map
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

        // Set the default tab to WW if it exists
        if (_categories.contains(_defaultCategory)) {
          int defaultIndex = _categories.indexOf(_defaultCategory);
          _subTabController.animateTo(defaultIndex);
        }
      });
    }
  }

  /// Implements lazy loading by incrementing the number of loaded items
  void _loadMoreItems() {
    setState(() {
      _loadedItemsCount += 20;
    });
  }

  /// Builds a grid of colors for a specific category
  /// Implements lazy loading and page-based organization
  Widget _buildColorGrid(List<dynamic> colors) {
    try {
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

            List<dynamic> colorsToShow = pageColors;
            if (pageIndex == pagesToShow.length - 1 &&
                totalItems > _loadedItemsCount) {
              int remainingItems =
                  _loadedItemsCount - (totalItems - pageColors.length);
              if (remainingItems > 0 && remainingItems <= pageColors.length) {
                colorsToShow = pageColors.sublist(0, remainingItems);
              }
            }

            if (!_pageCache.containsKey(pageNumber)) {
              _pageCache[pageNumber] =
                  _buildPageContent(pageNumber, colorsToShow);
            }
            return _pageCache[pageNumber]!;
          },
        ),
      );
    } catch (e) {
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

  /// Builds the content for a specific page of colors
  /// Creates a grid of color cards with proper styling
  Widget _buildPageContent(int pageNumber, List<dynamic> colors) {
    try {
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
              crossAxisCount: 4,
              childAspectRatio: 0.7,
            ),
            itemCount: colors.length,
            itemBuilder: (context, colorIndex) {
              final color = colors[colorIndex];
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
                        allColors: widget.allColors,
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
    } catch (e) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Error loading page content. Please try again.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  /// Main build method for OpusTabView
  /// Creates a tabbed interface for color categories
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

// Add AboutPage after ColorPalettePage
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI-Powered Color Palette',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This application leverages artificial intelligence to provide an intelligent color palette experience:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Smart Color Organization',
              'Colors are intelligently categorized and organized based on their properties and relationships.',
            ),
            _buildFeatureCard(
              'Dynamic Search',
              'AI-powered search functionality that understands color relationships and properties.',
            ),
            _buildFeatureCard(
              'Intelligent Recommendations',
              'Get smart suggestions for color combinations based on your selections.',
            ),
            _buildFeatureCard(
              'Interactive Drawing',
              'Create and manipulate color polygons with AI-assisted tools.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.23+23',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Add banner ad
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 50,
              child: AdWidget(
                ad: BannerAd(
                  adUnitId: 'ca-app-pub-6710120263757804/9278492126',
                  size: AdSize.banner,
                  request: const AdRequest(),
                  listener: BannerAdListener(
                    onAdLoaded: (ad) {},
                    onAdFailedToLoad: (ad, error) {
                      ad.dispose();
                    },
                  ),
                )..load(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
