import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../favorites_page.dart';
import '../providers/color_provider.dart';

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
  late ColorProvider colorProvider;

  final List<Color> defaultColors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    // Move provider initialization to after the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      colorProvider = Provider.of<ColorProvider>(context, listen: false);
    });
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

  Color hexToColor(String hexString) {
    try {
      // Remove any '#' prefix
      final hex = hexString.replaceAll('#', '');
      
      // Handle both 6-digit and 3-digit hex codes
      String fullHex = hex;
      if (hex.length == 3) {
        fullHex = hex.split('').map((e) => '$e$e').join('');
      }
      
      // Ensure 6 characters and add alpha channel
      fullHex = fullHex.padLeft(6, '0');
      return Color(int.parse('FF$fullHex', radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback color if parsing fails
    }
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.blue : Colors.grey,
            width: selectedColor == color ? 3 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteColorButton(String colorValue) {
    final color = hexToColor(colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedColor = color;
          });
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selectedColor == color ? Colors.white : Colors.grey,
              width: selectedColor == color ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorRow(Set<String> favoriteColors) {
    List<Widget> colorButtons = [];
    int favoritesAdded = 0;

    // Add favorite colors first
    for (String colorHex in favoriteColors) {
      if (favoritesAdded < 5) {  // Only show up to 5 colors in the top row
        colorButtons.add(_buildFavoriteColorButton(colorHex));
        favoritesAdded++;
      }
    }

    // Fill remaining slots with default colors if needed
    if (favoritesAdded < 5) {
      for (int i = favoritesAdded; i < 5; i++) {
        colorButtons.add(_buildColorButton(defaultColors[i]));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colorButtons,
    );
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
              // TODO: Implement save functionality
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
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
            ),
            const SizedBox(height: 8),
            Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<ColorProvider>(
                    builder: (context, colorProvider, _) {
                      final favoriteColors = colorProvider.favoriteColorNumbers;
                      return _buildColorRow(favoriteColors);
                    },
                  ),
                  const SizedBox(height: 5),
                  Consumer<ColorProvider>(
                    builder: (context, colorProvider, _) {
                      final favoriteColors = colorProvider.favoriteColorNumbers;
                      // Only show the scrollable row if there are more than 5 favorite colors
                      if (favoriteColors.length <= 5) return const SizedBox.shrink();
                      
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: favoriteColors
                              .skip(5) // Skip the first 5 colors that are shown in the top row
                              .map((colorHex) => _buildFavoriteColorButton(colorHex))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
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
      // Calculate scaling to fit the image within the canvas while maintaining aspect ratio
      final double imageAspectRatio = backgroundImage!.width / backgroundImage!.height;
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
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
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
