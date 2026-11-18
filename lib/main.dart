import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'services/daily_ad_service.dart';
import 'screens/daily_ad_gate_page.dart';

// Main entry point for the Color Palette application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
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

    // Count this app open (for first 20 app opens: no overlay or toast, normal use)
    DailyAdService.instance.incrementAppOpenCount();

    // Navigate to main screen or daily ad gate after animation
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final shouldGate = await DailyAdService.instance.shouldGateAccess();
      if (!mounted) return;
      if (shouldGate) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DailyAdGatePage()),
        );
      } else {
        // First 20 opens or already unlocked today: let user use as normal
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.red, width: 0.8),
                      ),
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
    return const ColorPaletteContent();
  }
}

class ColorPaletteContent extends StatefulWidget {
  const ColorPaletteContent({super.key});

  @override
  State<ColorPaletteContent> createState() => _ColorPaletteContentState();
}

/// State class for ColorPaletteContent
class _ColorPaletteContentState extends State<ColorPaletteContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadColorsAndFavorites();
    _mainTabController = TabController(length: 1, vsync: this);
    _mainTabController.addListener(_handleMainTabChange);
    _loadFavorites();
    _preloadTableColors();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainTabController.removeListener(_handleMainTabChange);
    _mainTabController.dispose();
    _asianTabController?.dispose();
    _tabViewCache.clear();
    _asianTabViewCache.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDailyAdGate();
    }
  }

  Future<void> _checkDailyAdGate() async {
    final shouldGate = await DailyAdService.instance.shouldGateAccess();
    if (shouldGate && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DailyAdGatePage()),
      );
    }
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
                  String page = (color['page'] ?? '').toString();
                  String colorNovaPage =
                      (color['cNP'] ?? color['colorNovaPage'] ?? color['details'] ?? '')
                          .toString();

                  bool nameMatch = name.toLowerCase().contains(normalizedQuery);
                  bool numberMatch =
                      number.toLowerCase().contains(normalizedQuery);
                  bool valueMatch =
                      value.toLowerCase().contains(normalizedQuery);
                  bool pageMatch = page.toLowerCase() == normalizedQuery ||
                      'page $page'.toLowerCase() == normalizedQuery;
                  bool novaMatch = (colorNovaPage.isNotEmpty &&
                          colorNovaPage.toLowerCase() == normalizedQuery) ||
                      (colorNovaPage.isNotEmpty &&
                          'color nova $colorNovaPage'.contains(normalizedQuery));

                  bool isMatch =
                      nameMatch || numberMatch || valueMatch || pageMatch || novaMatch;

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
      return ColorGridWithWheel(
        categoryColors: filteredColors[category] ?? [],
        category: category,
        onFavoriteToggle: toggleFavorite,
        isFavorite: isFavorite,
        allColors: colors,
        hexToColor: hexToColor,
        showWheel: true,
        isSearchActive: searchQuery.isNotEmpty,
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
            TabBar(
              isScrollable: true,
              tabs: visibleTabs
                  .map((tab) => Tab(text: tab.toUpperCase()))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
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
              SharePlus.instance.share(
                ShareParams(
                  text: 'Check out this amazing Color Palette app! https://play.google.com/store/apps/details?id=com.color.paletteasian',
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
            child: Row(
              children: [
                Expanded(
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
                      physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildColorGrid(List<dynamic> colors, String category) {
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

            // Using category in the key to prevent conflicts between different categories
            final cacheKey = '$category-$pageNumber'.hashCode;
            if (!_pageCache.containsKey(cacheKey)) {
              _pageCache[cacheKey] =
                  _buildPageContent(pageNumber, colorsToShow, category);
            }
            return _pageCache[cacheKey]!;
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

  Widget _buildPageContent(int pageNumber, List<dynamic> colors, String category) {
    try {
      final bool isWW = category.toUpperCase() == 'WW' ||
          colors.any((c) => c['number'].toString().toUpperCase().startsWith('WW'));
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWW ? 2 : 4,
              childAspectRatio: isWW ? 1.5 : 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, colorIndex) {
              final color = colors[colorIndex];
              final bool isColorWW =
                  color['number'].toString().toUpperCase().startsWith('WW');
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.red, width: 0.8),
                ),
                child: InkWell(
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
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.hexToColor(color['value']),
                              borderRadius: BorderRadius.circular(4),
                              border: isColorWW
                                  ? Border.all(color: Colors.black, width: 1)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isColorWW ? color['number'] : color['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isColorWW ? 12 : 10,
                            color: isColorWW ? Colors.black : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            physics: const NeverScrollableScrollPhysics(),
            children: _categories.map((category) {
              return _buildColorGrid(_categorizedColors[category] ?? [], category);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

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
  String _version = '';
  bool _isDailyUnlocked = false;

  @override
  void initState() {
    super.initState();
    // Only load ads on mobile platforms (not web)
    if (!kIsWeb) {
      _loadBannerAd();
      _loadRewardedAd();
    }
    _loadVersion();
    _checkDailyStatus();
  }

  Future<void> _checkDailyStatus() async {
    final unlocked = await DailyAdService.instance.isDailyAdUnlockedForToday();
    if (mounted) {
      setState(() {
        _isDailyUnlocked = unlocked;
      });
    }
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  void _loadBannerAd() {
    // Format: ca-app-pub-PUBLISHER_ID/AD_UNIT_ID
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-6710120263757804/9278492126', // Test banner ad unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('Banner ad loaded successfully');
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Failed to load banner ad: $error');
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
          debugPrint('Rewarded ad loaded successfully');
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
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
          debugPrint('Failed to show rewarded ad: $error');
          ad.dispose();
          _loadRewardedAd(); // Reload for next time
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // Handle reward
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          DailyAdService.instance.markDailyAdWatchedToday();
          if (mounted) {
            setState(() {
              _isDailyUnlocked = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Daily video ad watched! You have full ad-free access for the whole day.',
                ),
                backgroundColor: Colors.deepPurple,
                duration: Duration(seconds: 3),
              ),
            );
          }
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
            _buildFeatureCard(
              'Color Picker',
              'Pick colors from any image:\n'
                  '• Select Image: Choose an image from your gallery.\n'
                  '• Pick Color: Tap or drag on the image to select a color.\n'
                  '• View Details: See the color code and find similar colors in the database.',
            ),
            _buildFeatureCard(
              'Favorites',
              'Manage your favorite colors:\n'
                  '• Save: Tap the star icon on any color to save it.\n'
                  '• View: Access your favorites from the main menu.\n'
                  '• Categories: Switch between "All Favorites" and "Wood Colors".',
            ),
            _buildFeatureCard(
              'Full Screen View',
              'View colors in full screen:\n'
                  '• Open: Tap on any color detail to open full screen view.\n'
                  '• Close: Tap anywhere on the screen or use the close button.',
            ),
            const SizedBox(height: 16),
            if (_version.isNotEmpty) ...[
              Text(
                'Version $_version',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
            ],
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
            // Daily Ad Status & Explanation Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isDailyUnlocked
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        color: _isDailyUnlocked
                            ? Colors.green[700]
                            : Colors.deepPurple,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isDailyUnlocked
                              ? 'Daily Ad Watched'
                              : 'One-Time Ad for the Whole Day',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isDailyUnlocked
                                ? Colors.green[800]
                                : Colors.deepPurple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isDailyUnlocked
                        ? 'You have already watched today\'s ad! You can use the app for the whole day without watching any more ads.'
                        : 'This is a one-time ad for the whole day. You can use the app the whole day without watching the ad again. '
                            'We only show 1 ad per day to keep your color picking and drawing experience clean and completely free from frequent interruptions!',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Video Ad Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRewardedAdReady ? _showRewardedAd : null,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(
                  _isDailyUnlocked ? 'Watch Video Ad Again' : 'Watch Video Ad',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

class ColorGridWithWheel extends StatefulWidget {
  final List<dynamic> categoryColors;
  final String category;
  final Function(String) onFavoriteToggle;
  final bool Function(String) isFavorite;
  final Map<String, List<dynamic>> allColors;
  final Color Function(String) hexToColor;
  final bool showWheel;
  final bool isSearchActive;

  const ColorGridWithWheel({
    super.key,
    required this.categoryColors,
    required this.category,
    required this.onFavoriteToggle,
    required this.isFavorite,
    required this.allColors,
    required this.hexToColor,
    this.showWheel = false,
    this.isSearchActive = false,
  });

  @override
  State<ColorGridWithWheel> createState() => _ColorGridWithWheelState();
}

class _ColorGridWithWheelState extends State<ColorGridWithWheel> {
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _pageKeys = {};
  late List<int> _sortedPages;
  late Map<int, List<dynamic>> _colorsByPage;
  Map<int, dynamic> _lastColorOfAllPages = {};
  late List<int> _wheelPages;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _prepareData();
  }

  @override
  void didUpdateWidget(ColorGridWithWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryColors != widget.categoryColors ||
        oldWidget.allColors != widget.allColors) {
      _prepareData();
    }
  }

  void _prepareData() {
    _colorsByPage = {};
    for (var color in widget.categoryColors) {
      try {
        int page = int.tryParse(color['page']?.toString() ?? '206') ?? 206;
        if (!_colorsByPage.containsKey(page)) {
          _colorsByPage[page] = [];
        }
        _colorsByPage[page]!.add(color);
      } catch (e) {
        if (!_colorsByPage.containsKey(206)) {
          _colorsByPage[206] = [];
        }
        _colorsByPage[206]!.add(color);
      }
    }
    _sortedPages = _colorsByPage.keys.toList()..sort();
    _pageKeys.clear();
    for (var page in _sortedPages) {
      _pageKeys[page] = GlobalKey();
    }

    _lastColorOfAllPages = {};
    final allCategoryColors = widget.allColors[widget.category] ?? [];
    for (var color in allCategoryColors) {
      if (color == null) continue;
      final pageVal = color['page'];
      if (pageVal == null) continue;
      
      int page = int.tryParse(pageVal.toString()) ?? 0;
      if (page != 0) {
        _lastColorOfAllPages[page] = color;
      }
    }

    if (widget.category == 'medium') {
      List<int> allMediumPages = _lastColorOfAllPages.keys
          .where((p) => p >= 26 && p <= 255)
          .toList()
        ..sort();

      _wheelPages = [];
      for (int i = 0; i < allMediumPages.length; i += 11) {
        _wheelPages.add(allMediumPages[i]);
      }
      if (allMediumPages.isNotEmpty &&
          !_wheelPages.contains(allMediumPages.last)) {
        _wheelPages.add(allMediumPages.last);
      }
    } else {
      _wheelPages = _lastColorOfAllPages.keys.toList()..sort();
      if (_wheelPages.isEmpty) {
        _wheelPages = _sortedPages;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPage(int page, {bool isLive = false}) {
    int targetPage = page;
    if (!_pageKeys.containsKey(targetPage)) {
      if (_sortedPages.isEmpty) return;
      targetPage = _sortedPages.firstWhere(
        (p) => p >= page,
        orElse: () => _sortedPages.last,
      );
    }
    final key = _pageKeys[targetPage];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: isLive ? 100 : 300),
        curve: isLive ? Curves.linear : Curves.easeOutCubic,
      );
    } else if (_scrollController.hasClients && _sortedPages.isNotEmpty) {
      final pageIndex = _sortedPages.indexOf(targetPage);
      if (pageIndex != -1) {
        final targetOffset = (pageIndex / _sortedPages.length) *
            _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: isLive ? 100 : 300),
          curve: isLive ? Curves.linear : Curves.easeOutCubic,
        );
      }
    }
  }

  void _handleHorizontalBarInteraction(Offset localPosition, double width) {
    if (_wheelPages.isEmpty || width <= 0) return;

    double dx = localPosition.dx.clamp(0.0, width - 0.1);
    int index =
        (dx / width * _wheelPages.length).floor().clamp(0, _wheelPages.length - 1);

    if (_hoveredIndex != index) {
      setState(() {
        _hoveredIndex = index;
      });
      _scrollToPage(_wheelPages[index], isLive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryColors.isEmpty) {
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

    final bool showFixedHorizontalBar = widget.showWheel &&
        _wheelPages.isNotEmpty &&
        !widget.isSearchActive;

    return Column(
      children: [
        if (showFixedHorizontalBar)
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final activePage = _hoveredIndex != null &&
                      _hoveredIndex! < _wheelPages.length
                  ? _wheelPages[_hoveredIndex!]
                  : null;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MouseRegion(
                    onHover: (event) => _handleHorizontalBarInteraction(
                        event.localPosition, barWidth),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) => _handleHorizontalBarInteraction(
                          details.localPosition, barWidth),
                      onPanUpdate: (details) => _handleHorizontalBarInteraction(
                          details.localPosition, barWidth),
                      onTapDown: (details) => _handleHorizontalBarInteraction(
                          details.localPosition, barWidth),
                      onPanEnd: (_) => setState(() => _hoveredIndex = null),
                      onTapUp: (_) => setState(() => _hoveredIndex = null),
                      onTapCancel: () => setState(() => _hoveredIndex = null),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(barWidth, 40),
                            painter: HorizontalColorBarPainter(
                              pages: _wheelPages,
                              lastColors: _lastColorOfAllPages,
                              hexToColor: widget.hexToColor,
                              hoveredIndex: _hoveredIndex,
                            ),
                          ),
                          if (activePage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Page $activePage',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            key: PageStorageKey<String>(widget.category),
            slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 8)),
              for (var page in _sortedPages) ...[
                SliverToBoxAdapter(
                  key: _pageKeys[page],
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Page $page',
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
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: widget.isSearchActive ? 1.25 : 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        try {
                          final pageColors = _colorsByPage[page]!;
                          if (index >= pageColors.length) {
                            return const SizedBox.shrink();
                          }

                          var color = pageColors[index];
                          final colorNovaPage =
                              color['cNP'] ?? color['colorNovaPage'] ?? color['details'];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.red, width: 0.8),
                            ),
                            child: InkWell(
                              onTap: () {
                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ColorDetailPage(
                                        color: {
                                          ...color,
                                          'tab': widget.category,
                                        },
                                        onFavoriteToggle:
                                            widget.onFavoriteToggle,
                                        isFavorite:
                                            widget.isFavorite(color['number']),
                                        allColors: widget.allColors,
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
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              widget.hexToColor(color['value']),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      color['number'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (widget.isSearchActive &&
                                        colorNovaPage != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Color Nova: $colorNovaPage',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                      },
                      childCount: _colorsByPage[page]?.length ?? 0,
                    ),
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          ),
        ),
      ],
    );
  }
}

class HorizontalColorBarPainter extends CustomPainter {
  final List<int> pages;
  final Map<int, dynamic> lastColors;
  final Color Function(String) hexToColor;
  final int? hoveredIndex;

  HorizontalColorBarPainter({
    required this.pages,
    required this.lastColors,
    required this.hexToColor,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pages.isEmpty) return;

    final double itemWidth = size.width / pages.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final colorData = lastColors[page];
      if (colorData == null) continue;

      paint.color = hexToColor(colorData['value']);
      final rect = Rect.fromLTWH(i * itemWidth, 0, itemWidth, size.height);
      canvas.drawRect(rect, paint);

      if (pages.length < 100) {
        final linePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawLine(
          Offset(i * itemWidth, 0),
          Offset(i * itemWidth, size.height),
          linePaint,
        );
      }

      if (hoveredIndex == i) {
        final highlightPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRect(rect.deflate(1.2), highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalColorBarPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.pages != pages;
  }
}
