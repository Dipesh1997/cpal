import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../color_detail_page.dart';

class ColorPickerPage extends StatefulWidget {
  final Map<String, List<dynamic>>? initialColors;

  const ColorPickerPage({Key? key, this.initialColors}) : super(key: key);

  @override
  State<ColorPickerPage> createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  Map<String, List<dynamic>> colors = {};
  Color? selectedColor;
  final GlobalKey imageKey = GlobalKey();
  File? _image;
  ui.Image? _uiImage;
  bool _showSimilarColors = false;
  Set<String> _favoriteColors = {};

  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadFavorites();
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

  Future<void> toggleFavorite(String colorIdentifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];

      // Ensure we have a valid identifier
      if (colorIdentifier.isEmpty) return;

      if (favorites.contains(colorIdentifier)) {
        favorites.remove(colorIdentifier);
      } else {
        favorites.add(colorIdentifier);
      }
      await prefs.setStringList('favoriteColors', favorites);
      setState(() {
        _favoriteColors = favorites.toSet();
      });
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  bool isFavorite(String colorIdentifier) {
    if (colorIdentifier.isEmpty) return false;
    return _favoriteColors.contains(colorIdentifier);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File imageFile = File(image.path);
      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      setState(() {
        _image = imageFile;
        _uiImage = fi.image;
        selectedColor = Colors.transparent;
        _showSimilarColors = false;
      });
    }
  }

  Future<Color?> _getPixelColor(Offset localPosition) async {
    if (_uiImage == null) return null;

    try {
      final RenderBox? imageBox =
          imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (imageBox == null) return null;

      final Size imageSize = imageBox.size;

      // Convert local position to image coordinates
      final double normalizedX = localPosition.dx / imageSize.width;
      final double normalizedY = localPosition.dy / imageSize.height;

      final int x = (normalizedX * _uiImage!.width).round();
      final int y = (normalizedY * _uiImage!.height).round();

      // More strict bounds checking
      if (x < 0 || x >= _uiImage!.width || y < 0 || y >= _uiImage!.height) {
        return null;
      }

      final ByteData? byteData =
          await _uiImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final int offset = (y * _uiImage!.width + x) * 4;

      // Check if we have enough bytes to read RGBA values
      if (offset < 0 || offset + 3 >= byteData.lengthInBytes) {
        return null;
      }

      final int r = byteData.getUint8(offset);
      final int g = byteData.getUint8(offset + 1);
      final int b = byteData.getUint8(offset + 2);
      final int a = byteData.getUint8(offset + 3);

      return Color.fromARGB(a, r, g, b);
    } catch (e) {
      print('Error getting pixel color: $e');
      return null;
    }
  }

  void _handleTapDown(TapDownDetails details) async {
    final RenderBox? imageBox =
        imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (imageBox == null) return;

    final Offset localPosition = imageBox.globalToLocal(details.globalPosition);
    if (!imageBox.size.contains(localPosition)) return;

    final Color? color = await _getPixelColor(localPosition);
    if (color != null) {
      setState(() {
        selectedColor = color;
        _showSimilarColors = true;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) async {
    final RenderBox? imageBox =
        imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (imageBox == null) return;

    final Offset localPosition = imageBox.globalToLocal(details.globalPosition);
    if (!imageBox.size.contains(localPosition)) return;

    final Color? color = await _getPixelColor(localPosition);
    if (color != null) {
      setState(() {
        selectedColor = color;
        _showSimilarColors = true;
      });
    }
  }

  double _calculateColorSimilarity(Color color1, String color2Hex) {
    Color color2 = Color(int.parse('0xFF${color2Hex.replaceAll('#', '')}'));

    double rDiff = (color1.red - color2.red).abs().toDouble();
    double gDiff = (color1.green - color2.green).abs().toDouble();
    double bDiff = (color1.blue - color2.blue).abs().toDouble();

    // Calculate Euclidean distance in RGB space
    return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }

  double _calculateSimilarityPercentage(double distance) {
    // Max possible RGB distance is sqrt(255^2 * 3) ≈ 441.67
    const maxDistance = 441.67;
    // Convert distance to percentage (inverse relationship)
    return ((maxDistance - distance) / maxDistance * 100).clamp(0, 100);
  }

  List<Map<String, dynamic>> _findSimilarColors(Color color) {
    Map<String, List<Map<String, dynamic>>> categorizedColors = {
      'asian': [],
      'opus': [],
      'ncs': []
    };

    // Process all color categories
    colors.forEach((category, colorList) {
      for (var colorData in colorList) {
        try {
          String hex = colorData['value']?.toString().replaceAll('#', '') ?? '';
          if (hex.isEmpty) continue;

          double distance = _calculateColorSimilarity(color, hex);
          double similarityPercentage =
              _calculateSimilarityPercentage(distance);

          // Get the color number
          String number = colorData['number']?.toString().trim() ?? '';

          // Determine category based on number format and source
          String? categoryType;

          if (category == 'ncs') {
            categoryType = 'ncs';
          } else if (RegExp(r'^[A-Z]{2}\s\d{4}').hasMatch(number)) {
            // Matches patterns like "NN 9034"
            categoryType = 'opus';
          } else if (RegExp(r'^\d{4}$|^[A-Z0-9]{4}$')
              .hasMatch(number.replaceAll(' ', ''))) {
            // Matches 4-digit numbers or 4-character codes
            categoryType = 'asian';
          }

          // Skip if doesn't match any category
          if (categoryType == null) continue;

          Map<String, dynamic> colorInfo = {
            ...Map<String, dynamic>.from(colorData),
            'hex': colorData['value'],
            'category': categoryType,
            'similarity': distance,
            'similarityPercentage': similarityPercentage,
          };

          categorizedColors[categoryType]?.add(colorInfo);
        } catch (e) {
          print('Error processing color data: $e');
        }
      }
    });

    // Sort each category by similarity and take top 5
    List<Map<String, dynamic>> result = [];
    categorizedColors.forEach((category, colors) {
      colors.sort((a, b) =>
          (a['similarity'] as double).compareTo(b['similarity'] as double));
      result.addAll(colors.take(5));
    });

    return result;
  }

  Widget _buildSimilarColorCard(Map<String, dynamic> color) {
    String displayText = color['name'] ?? color['number'] ?? '';
    String category = color['category']?.toString().toUpperCase() ?? '';
    String colorIdentifier = color['number']?.toString() ??
        color['value']?.toString() ??
        color['hex']?.toString() ??
        '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ColorDetailPage(
                color: color,
                allColors: colors,
                onFavoriteToggle: toggleFavorite,
                isFavorite: isFavorite(colorIdentifier),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                          '0xFF${color['value'].toString().replaceAll('#', '')}')),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
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
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${color['number']} ($category)',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
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
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            color['value'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              isFavorite(colorIdentifier)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: isFavorite(colorIdentifier)
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: () => toggleFavorite(colorIdentifier),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarColorsList(List<Map<String, dynamic>> similarColors) {
    Map<String, List<Map<String, dynamic>>> groupedColors = {};
    for (var color in similarColors) {
      String category = color['category'] as String;
      groupedColors.putIfAbsent(category, () => []);
      groupedColors[category]!.add(color);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (String category in ['asian', 'opus', 'ncs'])
          if (groupedColors[category]?.isNotEmpty ?? false) ...[
            ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                '${category.toUpperCase()} (${groupedColors[category]?.length ?? 0})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: groupedColors[category]?.length ?? 0,
                  itemBuilder: (context, index) {
                    return _buildSimilarColorCard(
                        groupedColors[category]![index]);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildColorInfoSection() {
    List<Map<String, dynamic>> similarColors =
        selectedColor != null ? _findSimilarColors(selectedColor!) : [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: selectedColor != null
                          ? selectedColor
                          : Colors.grey[300],
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      selectedColor != null
                          ? 'HEX: #${selectedColor!.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}'
                          : 'Tap on image to pick color',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Similar Colors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              selectedColor != null
                  ? _buildSimilarColorsList(similarColors)
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadColors() async {
    if (widget.initialColors != null) {
      colors = widget.initialColors!;
    } else {
      // Load colors from asset
      try {
        final String jsonString = await DefaultAssetBundle.of(context)
            .loadString('assets/colors.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        colors = Map<String, List<dynamic>>.from(jsonData);
      } catch (e) {
        print('Error loading colors: $e');
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageHeight = screenSize.height * 0.4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Picker'),
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (_image == null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Select Image from Gallery'),
                ),
              )
            else
              Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTapDown: _handleTapDown,
                      onPanUpdate: _handlePanUpdate,
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: imageHeight,
                          maxWidth: screenSize.width * 0.8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          _image!,
                          key: imageKey,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  _buildColorInfoSection(),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: _image == null
          ? null
          : FloatingActionButton(
              onPressed: _pickImage,
              child: const Icon(Icons.image),
            ),
    );
  }
}
