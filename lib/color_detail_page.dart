import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorDetailPage extends StatefulWidget {
  final Map<String, dynamic> color;
  final Function(String) onFavoriteToggle;
  final bool isFavorite;

  const ColorDetailPage({
    super.key,
    required this.color,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  State<ColorDetailPage> createState() => _ColorDetailPageState();
}

class _ColorDetailPageState extends State<ColorDetailPage> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
  }

  Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.color['name']),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Page ${widget.color['page'] ?? 'N/A'}',
                style: TextStyle(
                  color: isFavorite ? Colors.yellow : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow : null,
            ),
            onPressed: () async {
              setState(() {
                isFavorite = !isFavorite;
                widget.onFavoriteToggle(widget.color['number']);
              });

              final prefs = await SharedPreferences.getInstance();
              if (isFavorite) {
                List<String> favoritePages =
                    prefs.getStringList('favorite_pages') ?? [];
                if (!favoritePages.contains(widget.color['page'].toString())) {
                  favoritePages.add(widget.color['page'].toString());
                  await prefs.setStringList('favorite_pages', favoritePages);
                }
              } else {
                List<String> favoritePages =
                    prefs.getStringList('favorite_pages') ?? [];
                favoritePages.remove(widget.color['page'].toString());
                await prefs.setStringList('favorite_pages', favoritePages);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            color: hexToColor(widget.color['value']),
            child: Container(
              width: double.infinity,
              height: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.color['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.color['number']} - ${widget.color['value']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
