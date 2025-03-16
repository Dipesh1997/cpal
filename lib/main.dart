import 'package:flutter/material.dart';
import 'dart:convert';
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

class _ColorPalettePageState extends State<ColorPalettePage> {
  Map<String, dynamic> colors = {};
  String searchQuery = '';
  Map<String, List<dynamic>> filteredColors = {};
  Set<String> favoriteColorNumbers = {};
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    loadColors();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteColorNumbers = prefs.getStringList('favorites')?.toSet() ?? {};
    });
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

  Future<void> loadColors() async {
    final String jsonString =
        await DefaultAssetBundle.of(context).loadString('assets/colors.json');
    setState(() {
      colors = json.decode(jsonString) as Map<String, dynamic>;
      filteredColors = Map.fromEntries(
        colors.entries.map((entry) => MapEntry(
              entry.key,
              (entry.value as List).cast<dynamic>(),
            )),
      );
    });
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
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget buildColorList(String category) {
    final categoryColors = filteredColors[category] ?? [];

    // If no colors, return empty container
    if (categoryColors.isEmpty) {
      return const Center(child: Text('No colors found'));
    }

    // Group colors by page
    Map<int, List<dynamic>> colorsByPage = {};
    for (var color in categoryColors) {
      int page = color['page'] ?? 1;
      if (!colorsByPage.containsKey(page)) {
        colorsByPage[page] = [];
      }
      colorsByPage[page]!.add(color);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount:
          colorsByPage.length * 2, // Alternate between page header and colors
      itemBuilder: (context, index) {
        if (index.isOdd) {
          // Page number display
          final pageNumber = colorsByPage.keys.toList()[index ~/ 2];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Page $pageNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          // Colors for the page
          final pageNumber = colorsByPage.keys.toList()[index ~/ 2];
          final pageColors = colorsByPage[pageNumber]!;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.7,
            ),
            itemCount: pageColors.length,
            itemBuilder: (context, colorIndex) {
              final color = pageColors[colorIndex];
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
          );
        }
      },
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
                    tabs: categories
                        .map((category) => Tab(text: category.capitalize()))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        body: categories.isEmpty
            ? const Center(child: Text('No results found'))
            : TabBarView(
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
