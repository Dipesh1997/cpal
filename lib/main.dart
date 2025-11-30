import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';

// Main entry point for the Color Palette application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize Google Mobile Ads only on mobile platforms (not web)
  if (!kIsWeb) {
    // Fire and forget - don't await to unblock startup
    MobileAds.instance.initialize().then((_) {
      debugPrint('Mobile Ads Initialized');
    }).catchError((error) {
      debugPrint('Failed to initialize Mobile Ads: $error');
    });
  }
  runApp(const MyApp());
}

/// Root widget of the application
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Simulate typing animation - faster start
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _startTypingAnimation();
    });

    // Show results after typing - faster
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showResults = true;
        });
      }
    });

    // Navigate to main screen after animation - reduced from 2s to 1.2s
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ColorPalettePage()),
        );
      }
    });
  }

  void _startTypingAnimation() {
    Future.doWhile(() async {
      if (_currentIndex < _targetText.length) {
        if (mounted) {
          setState(() {
            _searchText += _targetText[_currentIndex];
            _currentIndex++;
          });
        }
        await Future.delayed(const Duration(milliseconds: 50)); // Faster typing
        return true;
      } else {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
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
              SizedBox(
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
                      child: Padding(
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
                    const SizedBox(height: 14),
                    const Text(
                      'By Golden Paints',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.yellowAccent,
                        fontStyle: FontStyle.italic,
                        backgroundColor: Colors.black,
                      ),
                      textAlign: TextAlign.center,
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
class ColorPalettePage extends StatelessWidget {
  const ColorPalettePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const ColorPaletteContent(),
    );
  }
}

class ColorPaletteContent extends StatefulWidget {
  const ColorPaletteContent({super.key});

  @override
  State<ColorPaletteContent> createState() => _ColorPaletteContentState();
}

/// State class for ColorPaletteContent
class _ColorPaletteContentState extends State<ColorPaletteContent>
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

  // Cache management
  final Map<String, Color> _colorCache = {};
  final Map<int, Widget> _tabViewCache = {};
  final Map<String, Widget> _asianTabViewCache = {};
  bool _isPreloading = false;

  // Preloaded colors for ColorTablePage
  static Map<String, List<dynamic>>? _preloadedTableColors;

  // Showcase keys
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _tabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadColorsAndFavorites();
    _mainTabController = TabController(length: 1, vsync: this);
    _mainTabController.addListener(_handleMainTabChange);
    _loadFavorites();
    _preloadTableColors();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowShowcase();
    });
  }

  Future<void> _checkAndShowShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShownTutorial = prefs.getBool('hasShownTutorial') ?? false;

    if (!hasShownTutorial && mounted) {
      ShowCaseWidget.of(context).startShowCase([_searchKey, _tabKey]);
      await prefs.setBool('hasShownTutorial', true);
    }
  }

  @override
  void dispose() {
    _mainTabController.removeListener(_handleMainTabChange);
    _mainTabController.dispose();
    _asianTabController?.dispose();
    _tabViewCache.clear();
    _asianTabViewCache.clear();
    super.dispose();
  }

  void _handleMainTabChange() {
    if (_mainTabController.indexIsChanging) {
      if (mounted) {
        setState(() {
          _tabViewCache.clear();
          _asianTabViewCache.clear();
        });
      }
    }
  }

  Future<void> _preloadTabViews() async {
    if (_isPreloading) return;
    _isPreloading = true;

    List<String> asianTabs = ['light', 'medium', 'dark', 'SA', 'SV'];
    for (var tab in asianTabs) {
      if ((filteredColors[tab] ?? []).isNotEmpty) {
        _asianTabViewCache[tab] = _buildColorGrid(tab);
      }
    }

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

  Future<void> loadColorsAndFavorites() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await _loadColors();
    await _preloadTabViews();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadColors() async {
    try {
      if (mounted) {
        setState(() {
          colors = {
            'light': LightColors.colors,
            'medium': MediumColors.colors,
            'dark': DarkColors.colors,
            'SA': SaColors.colors,
            'SV': SvColors.colors,
            'opus': OpusColors.colors,
          };
          filteredColors = Map.fromEntries(
            colors.entries.map((entry) => MapEntry(
                  entry.key,
                  entry.value,
                )),
          );
        });
      }
    } catch (e) {
      // Error loading colors
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];
      if (mounted) {
        setState(() {
          _favoriteColors = favorites.toSet();
        });
      }
    } catch (e) {
      // Error loading favorites
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
      if (mounted) {
        setState(() {
          _favoriteColors = favorites.toSet();
        });
      }
    } catch (e) {
      // Error toggling favorite
    }
  }

  bool isFavorite(String colorNumber) {
    return _favoriteColors.contains(colorNumber);
  }

  void filterColors(String query) {
    if (mounted) {
      setState(() {
        searchQuery = query;

        if (query.isEmpty) {
          filteredColors = Map.fromEntries(
            colors.entries.map((entry) => MapEntry(
                  entry.key,
                  entry.value,
                )),
          );
        } else {
          String normalizedQuery = query.toLowerCase().trim();

          filteredColors = Map.fromEntries(
            colors.entries.map((entry) {
              final allCategoryColors = entry.value;

              final filteredCategoryColors = allCategoryColors.where((color) {
                try {
                  String name = (color['name'] ?? '').toString();
                  String number = (color['number'] ?? '').toString();
                  String value = (color['value'] ?? '').toString();

                  bool nameMatch = name.toLowerCase().contains(normalizedQuery);
                  bool numberMatch =
                      number.toLowerCase().contains(normalizedQuery);
                  bool valueMatch =
                      value.toLowerCase().contains(normalizedQuery);

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
    }

    _tabViewCache.clear();
    _asianTabViewCache.clear();

    if (mounted) {
      setState(() {});
    }
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

  Widget _buildColorGrid(String category) {
    try {
      final categoryColors = filteredColors[category] ?? [];

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
        try {
          int page = int.tryParse(color['page']?.toString() ?? '206') ?? 206;
          if (!colorsByPage.containsKey(page)) {
            colorsByPage[page] = [];
          }
          colorsByPage[page]!.add(color);
        } catch (e) {
          if (!colorsByPage.containsKey(206)) {
            colorsByPage[206] = [];
          }
          colorsByPage[206]!.add(color);
        }
      }

      List<int> sortedPages = colorsByPage.keys.toList()..sort();

      return CustomScrollView(
        key: PageStorageKey<String>(category),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 8)),
          for (var pageIndex = 0;
              pageIndex < sortedPages.length;
              pageIndex++) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Page ${sortedPages[pageIndex]}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    try {
                      final pageColors = colorsByPage[sortedPages[pageIndex]]!;
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
                                  content: Text('Error loading color details'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Padding(
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
                  childCount: colorsByPage[sortedPages[pageIndex]]?.length ?? 0,
                ),
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
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

  Widget _buildAsianTabView() {
    try {
      List<String> asianTabs = ['light', 'medium', 'dark', 'SA', 'SV'];
      List<String> visibleTabs = [];

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
            Showcase(
              key: _tabKey,
              description:
                  'Switch between different color categories (Light, Medium, Dark, etc.)',
              child: TabBar(
                isScrollable: true,
                tabs: visibleTabs
                    .map((tab) => Tab(text: tab.toUpperCase()))
                    .toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: visibleTabs.map((tab) {
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

  @override
  Widget build(BuildContext context) {
    List<Widget> visibleTabs = [];

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

    if ((filteredColors['opus'] ?? []).isNotEmpty) {
      visibleTabs.add(const Tab(text: 'OPUS'));
    }

    if (_mainTabController.length != visibleTabs.length) {
      _mainTabController.removeListener(_handleMainTabChange);
      _mainTabController.dispose();
      _mainTabController =
          TabController(length: visibleTabs.length, vsync: this);
      _mainTabController.addListener(_handleMainTabChange);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palette'),
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
          IconButton(
            icon: const Icon(Icons.chair_alt_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ColorTablePage(
                    onFavoriteToggle: toggleFavorite,
                    favoriteColorNumbers: _favoriteColors,
                  ),
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
                    allColors: colors,
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
                  child: Showcase(
                    key: _searchKey,
                    description: 'Search colors by name, number, or value',
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search colors by name, number, or value...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        filterColors(value);
                      },
                    ),
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
}

/// Extension to add string capitalization functionality
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

/// Widget for displaying Opus colors in a grid
class OpusTabView extends StatefulWidget {
  final List<dynamic> colors;
  final Function(String) onFavoriteToggle;
  final Set<String> favoriteColorNumbers;
  final Map<String, List<dynamic>> filteredColors;
  final Map<String, List<dynamic>> allColors;
  final Function(String) hexToColor;

  const OpusTabView({
    super.key,
    required this.colors,
    required this.onFavoriteToggle,
    required this.favoriteColorNumbers,
    required this.filteredColors,
    required this.allColors,
    required this.hexToColor,
  });

  @override
  State<OpusTabView> createState() => _OpusTabViewState();
}

/// State class for OpusTabView
class _OpusTabViewState extends State<OpusTabView>
    with TickerProviderStateMixin {
  late TabController _subTabController;
  Map<String, List<dynamic>> _categorizedColors = {};
  List<String> _categories = ['All'];
  int _loadedItemsCount = 20;
  final String _defaultCategory = 'WW';
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _categorizeColors();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _pageCache.clear();
    super.dispose();
  }

  void _categorizeColors() {
    _categorizedColors = {'All': widget.colors};

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

    List<String> sortedPrefixes = tempCategories.keys.toList();
    sortedPrefixes.sort((a, b) {
      int minPageA = tempCategories[a]!.fold<int>(
          double.maxFinite.toInt(),
          (min, color) => math.min(
              min,
              int.tryParse(color['page']?.toString() ?? '') ??
                  double.maxFinite.toInt()));
      int minPageB = tempCategories[b]!.fold<int>(
          double.maxFinite.toInt(),
          (min, color) => math.min(
              min,
              int.tryParse(color['page']?.toString() ?? '') ??
                  double.maxFinite.toInt()));
      return minPageA.compareTo(minPageB);
    });

    for (var prefix in sortedPrefixes) {
      _categorizedColors[prefix] = tempCategories[prefix]!;
    }

    _categories = ['All', ...sortedPrefixes];

    if (mounted) {
      setState(() {
        _subTabController =
            TabController(length: _categories.length, vsync: this);

        if (_categories.contains(_defaultCategory)) {
          int defaultIndex = _categories.indexOf(_defaultCategory);
          _subTabController.animateTo(defaultIndex);
        }
      });
    }
  }

  void _loadMoreItems() {
    if (mounted) {
      setState(() {
        _loadedItemsCount += 20;
      });
    }
  }

  Widget _buildColorGrid(List<dynamic> colors) {
    try {
      Map<int, List<dynamic>> colorsByPage = {};
      for (var color in colors) {
        int page = int.tryParse(color['page']?.toString() ?? '1') ?? 1;
        if (!colorsByPage.containsKey(page)) {
          colorsByPage[page] = [];
        }
        colorsByPage[page]!.add(color);
      }

      List<int> sortedPages = colorsByPage.keys.toList()..sort();

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
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  @override
  void initState() {
    super.initState();
    // Only load ads on mobile platforms (not web)
    if (!kIsWeb) {
      _loadBannerAd();
      _loadRewardedAd();
    }
  }

  void _loadBannerAd() {
    // Using test ad unit ID for development
    // Replace with your actual banner ad unit ID for production
    // Test ID: ca-app-pub-3940256099942544/6300978111
    // Format: ca-app-pub-PUBLISHER_ID/AD_UNIT_ID
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-6710120263757804/9278492126', // Test banner ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('Banner ad loaded successfully');
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: $error');
          ad.dispose();
          setState(() {
            _isBannerAdReady = false;
          });
        },
      ),
    )..load();
  }

  void _loadRewardedAd() {
    // Load rewarded video ad
    // Using test ad unit ID for development
    // Replace with your actual rewarded ad unit ID for production
    // Test ID: ca-app-pub-3940256099942544/5224354917
    // Format: ca-app-pub-PUBLISHER_ID/AD_UNIT_ID
    RewardedAd.load(
      adUnitId:
          'ca-app-pub-6710120263757804/7307204400', // Test rewarded ad unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('Rewarded ad loaded successfully');
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad: $error');
          setState(() {
            _isRewardedAdReady = false;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null && _isRewardedAdReady) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd(); // Reload for next time
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Failed to show rewarded ad: $error');
          ad.dispose();
          _loadRewardedAd(); // Reload for next time
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // Handle reward
          print('User earned reward: ${reward.amount} ${reward.type}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reward earned: ${reward.amount} ${reward.type}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video ad is not ready yet. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

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
            const SizedBox(height: 16),
            const Text(
              'How to Use',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Searching Colors',
              'You can search for colors using their name, number, or hex value. Simply tap the search bar at the top and start typing.',
            ),
            _buildFeatureCard(
              'Color Categories',
              'Colors are organized into categories: Light, Medium, Dark, and others. Use the tabs below the search bar to switch between these categories.',
            ),
            _buildFeatureCard(
              'Drawing Canvas',
              'Create your own designs using the Drawing Canvas:\n'
                  '• Add Background: Import an image to draw over.\n'
                  '• Create Polygons: Tap "New" (+) and tap on the canvas to create points. Tap "Finish" (✓) to complete a shape.\n'
                  '• Change Colors: Tap on any completed polygon to change its color or opacity.\n'
                  '• Manage Walls: Use the list view to rename, delete, or edit specific walls.\n'
                  '• Share: Export and share your creation with others.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.40+40',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            // Ad Button/Container
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isBannerAdReady && _bannerAd != null
                  ? SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading ad...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Video Ad Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRewardedAdReady ? _showRewardedAd : null,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text(
                  'Watch Video Ad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
