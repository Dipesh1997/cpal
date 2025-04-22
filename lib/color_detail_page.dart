import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/full_screen_color_page.dart';

class ColorDetailPage extends StatefulWidget {
  final Map<String, dynamic> color;
  final Map<String, List<dynamic>> allColors;
  final Function(String) onFavoriteToggle;
  final bool isFavorite;

  const ColorDetailPage({
    Key? key,
    required this.color,
    required this.allColors,
    required this.onFavoriteToggle,
    required this.isFavorite,
  }) : super(key: key);

  @override
  State<ColorDetailPage> createState() => _ColorDetailPageState();
}

class _ColorDetailPageState extends State<ColorDetailPage> {
  bool _isFavorite = false;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _similarColors = [];

  // Use a static cache for color conversion
  static final Map<String, Color> _colorCache = {};

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _findSimilarColors();
  }

  void _handleFavoriteToggle() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // Ensure we have a valid color number or hex value
    String colorIdentifier = widget.color['number']?.toString() ??
        widget.color['value']?.toString() ??
        widget.color['hex']?.toString() ??
        '';
    if (colorIdentifier.isNotEmpty) {
      widget.onFavoriteToggle(colorIdentifier);
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

    // Store in cache
    _colorCache[hexString] = color;
    return color;
  }

  // Calculate color similarity using RGB values
  double _calculateColorSimilarity(String color1Hex, String color2Hex) {
    Color color1 = hexToColor(color1Hex);
    Color color2 = hexToColor(color2Hex);

    double rDiff = (color1.red - color2.red).abs().toDouble();
    double gDiff = (color1.green - color2.green).abs().toDouble();
    double bDiff = (color1.blue - color2.blue).abs().toDouble();

    // Calculate Euclidean distance in RGB space
    return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }

  // Calculate similarity percentage (higher number means more similar)
  double _calculateSimilarityPercentage(double distance) {
    // Max possible RGB distance is sqrt(255^2 * 3) ≈ 441.67
    const maxDistance = 441.67;
    // Convert distance to percentage (inverse relationship)
    return ((maxDistance - distance) / maxDistance * 100).clamp(0, 100);
  }

  void _findSimilarColors() {
    String currentTab = widget.color['tab'] ?? 'opus'; // Get current tab
    List<Map<String, dynamic>> allSimilarColors = [];

    // If current tab is opus or ncs, show colors from light/medium/dark
    // If current tab is light/medium/dark, show colors from opus
    if (currentTab == 'opus' ||
        currentTab == 'ncs' ||
        widget.color['number']?.toString().contains('-N') == true) {
      // For opus and ncs colors, show similar colors from light, medium, and dark tabs
      ['light', 'medium', 'dark'].forEach((tab) {
        if (widget.allColors.containsKey(tab)) {
          for (var color in widget.allColors[tab]!) {
            if (color is Map<String, dynamic>) {
              double distance = _calculateColorSimilarity(
                widget.color['value'],
                color['value'],
              );
              double similarityPercentage =
                  _calculateSimilarityPercentage(distance);
              allSimilarColors.add({
                ...color,
                'similarity': distance,
                'similarityPercentage': similarityPercentage,
                'tab': tab,
              });
            }
          }
        }
      });
    } else {
      // For light/medium/dark colors, show similar colors from opus tab only
      if (widget.allColors.containsKey('opus')) {
        for (var color in widget.allColors['opus']!) {
          if (color is Map<String, dynamic>) {
            double distance = _calculateColorSimilarity(
              widget.color['value'],
              color['value'],
            );
            double similarityPercentage =
                _calculateSimilarityPercentage(distance);
            allSimilarColors.add({
              ...color,
              'similarity': distance,
              'similarityPercentage': similarityPercentage,
              'tab': 'opus',
            });
          }
        }
      }
    }

    // Sort by similarity and take top 5
    allSimilarColors.sort((a, b) =>
        (a['similarity'] as double).compareTo(b['similarity'] as double));
    setState(() {
      _similarColors = allSimilarColors.take(5).toList();
    });
  }

  String _getDisplayTitle() {
    if (widget.color['tab'] == 'ncs') {
      return 'Color ${widget.color['number']}';
    }
    return widget.color['name'] ?? 'N/A';
  }

  Widget _buildColorInfo() {
    List<Widget> details = [];

    if (widget.color['tab'] == 'ncs') {
      details = [
        Text(
          'Number: ${widget.color['number']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Position: ${widget.color['position']}',
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hex Code: ${widget.color['value']}',
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ];
    } else {
      details = [
        Text(
          'Number: ${widget.color['number']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Name: ${widget.color['name']}',
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hex Code: ${widget.color['value']}',
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tab: ${widget.color['tab'].toString().toUpperCase()}',
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  Widget _buildSimilarColorCard(Map<String, dynamic> color) {
    String displayText = color['tab'] == 'ncs'
        ? 'Position: ${color['position']}'
        : color['name'];

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ColorDetailPage(
                color: {
                  ...color,
                  'tab': color['tab'],
                },
                allColors: widget.allColors,
                onFavoriteToggle: widget.onFavoriteToggle,
                isFavorite: _isFavorite,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hexToColor(color['value']),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${color['number']} (${color['tab'].toString().toUpperCase()})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${color['similarityPercentage'].toStringAsFixed(1)}% Match',
                    style: TextStyle(
                      color: color['similarityPercentage'] >= 90
                          ? Colors.green
                          : color['similarityPercentage'] >= 75
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    color['value'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getDisplayTitle()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Page ${widget.color['page'] ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : Colors.grey,
            ),
            onPressed: _handleFavoriteToggle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: hexToColor(widget.color['value']),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenColorPage(
                              colorHex: widget.color['value'],
                              colorName: _getDisplayTitle(),
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child:
                          const Icon(Icons.fullscreen, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildColorInfo(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Similar Colors'),
              initiallyExpanded: _isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isExpanded = expanded;
                });
              },
              children: [
                ..._similarColors.map((color) => _buildSimilarColorCard(color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
