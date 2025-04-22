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

class FavoritesPage extends StatelessWidget {
  final Map<String, dynamic> allColors;
  final Set<String> favoriteColorNumbers;
  final Function(String) onFavoriteToggle;

  const FavoritesPage({
    super.key,
    required this.allColors,
    required this.favoriteColorNumbers,
    required this.onFavoriteToggle,
  });

  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  List<Map<String, dynamic>> getFavoriteColors() {
    List<Map<String, dynamic>> favorites = [];
    allColors.forEach((category, colors) {
      for (var color in colors) {
        // Skip colors that don't have required fields
        if (color == null || color['number'] == null || color['value'] == null)
          continue;

        if (favoriteColorNumbers.contains(color['number'])) {
          // Ensure all required fields have default values
          favorites.add({
            ...color,
            'name':
                color['name'] ?? '', // Default to empty string if name is null
            'number': color['number'],
            'value': color['value'],
          });
        }
      }
    });
    return favorites;
  }

  @override
  Widget build(BuildContext context) {
    final favoriteColors = getFavoriteColors();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Colors'),
      ),
      body: favoriteColors.isEmpty
          ? const Center(child: Text('No favorite colors yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: favoriteColors.length,
              itemBuilder: (context, index) {
                final color = favoriteColors[index];
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
                          onFavoriteToggle: onFavoriteToggle,
                          isFavorite: true,
                          allColors: allColors.map((key, value) =>
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
    );
  }
}
