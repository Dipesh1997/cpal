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

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoriteColors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateFavoriteColors();
  }

  @override
  void didUpdateWidget(FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favoriteColorNumbers != widget.favoriteColorNumbers) {
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
    // Clear existing favorites
    List<Map<String, dynamic>> favorites = [];

    // Rebuild favorites list from current state
    widget.allColors.forEach((category, colors) {
      for (var color in colors) {
        if (color == null ||
            color['number'] == null ||
            color['value'] == null) {
          continue;
        }

        // Only add if the color is currently in favoriteColorNumbers
        if (widget.favoriteColorNumbers.contains(color['number'].toString())) {
          favorites.add({
            ...color,
            'name': color['name'] ?? '',
            'number': color['number'],
            'value': color['value'],
          });
        }
      }
    });

    // Update state with new favorites list
    if (mounted) {
      setState(() {
        _favoriteColors = favorites;
      });
    }
  }

  void _handleFavoriteToggle(String colorNumber) {
    widget.onFavoriteToggle(colorNumber);
    // The didUpdateWidget will handle the update
  }

  Future<void> _handleRefresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Colors'),
      ),
      body: _favoriteColors.isEmpty
          ? RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No favorite colors yet'),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _favoriteColors.length,
                itemBuilder: (context, index) {
                  final color = _favoriteColors[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ColorDetailPage(
                            color: {
                              ...color,
                              'tab': 'favorites',
                            },
                            onFavoriteToggle: _handleFavoriteToggle,
                            isFavorite: true,
                            allColors: widget.allColors.map((key, value) =>
                                MapEntry(key, value as List<dynamic>)),
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
              ),
            ),
    );
  }
}
