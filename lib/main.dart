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
        filteredColors = Map.fromEntries(
          colors.entries.map((entry) {
            final filtered = (entry.value as List).where((color) {
              return color['name']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  color['number']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase());
            }).toList();
            return MapEntry(entry.key, filtered);
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

  int getStartingPageNumber(String currentCategory, List<String> categories) {
    int startPage = 1;
    int categoryIndex = categories.indexOf(currentCategory);

    for (int i = 0; i < categoryIndex; i++) {
      final previousColors = filteredColors[categories[i]] ?? [];
      startPage += (previousColors.length / 8).ceil();
    }

    return startPage;
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
                  final categoryColors = filteredColors[category] ?? [];
                  final pages = (categoryColors.length / 8).ceil();
                  final startPage = getStartingPageNumber(category, categories);

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount:
                        pages * 2, // Modified to include last page number
                    itemBuilder: (context, index) {
                      if (index.isOdd) {
                        // Page number display
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'Page ${startPage + (index ~/ 2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      final pageIndex = index ~/ 2;
                      final startIndex = pageIndex * 8;
                      final endIndex =
                          (startIndex + 8).clamp(0, categoryColors.length);
                      final pageColors =
                          categoryColors.sublist(startIndex, endIndex);

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
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
                                    isFavorite: favoriteColorNumbers
                                        .contains(color['number']),
                                    onFavoriteToggle: toggleFavorite,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              color: hexToColor(color['value']), // Add this
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                    if (favoriteColorNumbers
                                        .contains(color['number']))
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.yellow,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
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
