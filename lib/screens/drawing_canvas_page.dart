import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

class DrawingCanvasPage extends StatefulWidget {
  const DrawingCanvasPage({super.key});

  @override
  State<DrawingCanvasPage> createState() => _DrawingCanvasPageState();
}

class _DrawingCanvasPageState extends State<DrawingCanvasPage> {
  List<DrawingPoint?> drawingPoints = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 5;
  File? backgroundImage;
  ui.Image? renderedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> _colorsData = {};
  Set<String> _favoriteColors = {};

  @override
  void initState() {
    super.initState();
    _loadColorsAndFavorites();
  }

  Future<void> _loadColorsAndFavorites() async {
    // Load colors from colors.json
    final colorsJson =
        await DefaultAssetBundle.of(context).loadString('assets/colors.json');
    setState(() {
      _colorsData = json.decode(colorsJson);
    });

    // Load favorites from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favoriteColors = favorites.toSet();
    });
  }

  Color hexToColor(String hexString) {
    try {
      final hex = hexString.replaceAll('#', '');
      String fullHex = hex;
      if (hex.length == 3) {
        fullHex = hex.split('').map((e) => '$e$e').join('');
      }
      fullHex = fullHex.padLeft(6, '0');
      return Color(int.parse('FF$fullHex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showColorPalette(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        try {
          if (_favoriteColors.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No favorite colors yet. Mark some colors as favorites to see them here!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Get valid color sets that have favorite colors
          final validColorSets = _colorsData.entries.where((entry) {
            try {
              final colorSet = entry.value as List?;
              if (colorSet == null || colorSet.isEmpty) return false;

              return colorSet.any((color) {
                if (color is Map<String, dynamic>) {
                  final number = color['number']?.toString();
                  return number != null && _favoriteColors.contains(number);
                }
                return false;
              });
            } catch (e) {
              debugPrint('Error processing color set ${entry.key}: $e');
              return false;
            }
          }).toList();

          if (validColorSets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No favorite colors found in any color set',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return DefaultTabController(
            length: validColorSets.length,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Color',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    isScrollable: true,
                    tabs: validColorSets
                        .map((entry) => Tab(text: entry.key))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: validColorSets.map((entry) {
                        try {
                          final colorSet = entry.value as List;
                          final favoriteColorsInSet = colorSet.where((color) {
                            try {
                              if (color is Map<String, dynamic>) {
                                final number = color['number']?.toString();
                                return number != null &&
                                    _favoriteColors.contains(number);
                              }
                              return false;
                            } catch (e) {
                              debugPrint('Error processing color: $e');
                              return false;
                            }
                          }).toList();

                          if (favoriteColorsInSet.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No favorite colors found in this set',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: favoriteColorsInSet.length,
                              itemBuilder: (context, index) {
                                try {
                                  if (index >= favoriteColorsInSet.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final color = favoriteColorsInSet[index];
                                  if (color is! Map<String, dynamic>) {
                                    return const SizedBox.shrink();
                                  }

                                  final hexColor = color['value']?.toString();
                                  if (hexColor == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final colorObj = hexToColor(hexColor);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedColor = colorObj;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorObj,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedColor == colorObj
                                              ? Colors.white
                                              : Colors.grey,
                                          width:
                                              selectedColor == colorObj ? 3 : 1,
                                        ),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint(
                                      'Error building color item at index $index: $e');
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          );
                        } catch (e) {
                          debugPrint(
                              'Error processing color set ${entry.key}: $e');
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Error loading colors from this set',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error in color palette: $e');
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Something went wrong while loading the color palette. Please try again.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File imageFile = File(image.path);
        final data = await imageFile.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(data);
        final ui.FrameInfo fi = await codec.getNextFrame();
        setState(() {
          backgroundImage = imageFile;
          renderedImage = fi.image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.8;
    final double height = width * 1.4142; // Portrait aspect ratio (A4)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => _showColorPalette(context),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                drawingPoints.clear();
                backgroundImage = null;
                renderedImage = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          drawingPoints.add(
                            DrawingPoint(
                              offset: details.localPosition,
                              paint: Paint()
                                ..color = selectedColor
                                ..isAntiAlias = true
                                ..strokeWidth = strokeWidth
                                ..strokeCap = StrokeCap.round,
                            ),
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          drawingPoints.add(
                            DrawingPoint(
                              offset: details.localPosition,
                              paint: Paint()
                                ..color = selectedColor
                                ..isAntiAlias = true
                                ..strokeWidth = strokeWidth
                                ..strokeCap = StrokeCap.round,
                            ),
                          );
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          drawingPoints.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: _DrawingPainter(
                          drawingPoints: drawingPoints,
                          backgroundImage: renderedImage,
                        ),
                        size: Size(width, height),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: strokeWidth,
                    min: 1,
                    max: 20,
                    onChanged: (value) {
                      setState(() {
                        strokeWidth = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final ui.Image? backgroundImage;

  _DrawingPainter({required this.drawingPoints, this.backgroundImage});

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      final double imageAspectRatio =
          backgroundImage!.width / backgroundImage!.height;
      final double canvasAspectRatio = size.width / size.height;

      double scaleX = size.width / backgroundImage!.width;
      double scaleY = size.height / backgroundImage!.height;

      if (imageAspectRatio > canvasAspectRatio) {
        scaleY = scaleX;
      } else {
        scaleX = scaleY;
      }

      final double scaledWidth = backgroundImage!.width * scaleX;
      final double scaledHeight = backgroundImage!.height * scaleY;

      final double offsetX = (size.width - scaledWidth) / 2;
      final double offsetY = (size.height - scaledHeight) / 2;

      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(),
            backgroundImage!.height.toDouble()),
        Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight),
        Paint(),
      );
    }

    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        canvas.drawLine(
          drawingPoints[i]!.offset,
          drawingPoints[i + 1]!.offset,
          drawingPoints[i]!.paint,
        );
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        canvas.drawPoints(
          ui.PointMode.points,
          [drawingPoints[i]!.offset],
          drawingPoints[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
