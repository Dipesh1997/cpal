import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import '../lightcolors.dart';
import '../mediumcolors.dart';
import '../darkcolors.dart';
import '../sacolors.dart';
import '../svcolors.dart';
import '../opuscolors.dart';
import '../ncscolors.dart';
import '../woodcolors.dart';
import 'package:showcaseview/showcaseview.dart';

/// A class representing a drawing point with its position and paint properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

/// The main drawing canvas page widget that allows users to draw polygons and holes
class DrawingCanvasPage extends StatelessWidget {
  const DrawingCanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const DrawingCanvasContent(),
    );
  }
}

class DrawingCanvasContent extends StatefulWidget {
  const DrawingCanvasContent({super.key});

  @override
  State<DrawingCanvasContent> createState() => _DrawingCanvasContentState();
}

/// The state class for the drawing canvas page
class _DrawingCanvasContentState extends State<DrawingCanvasContent> {
  // Image picker instance for selecting background images
  final ImagePicker _picker = ImagePicker();

  // Lists to store points for current polygon and hole being drawn
  List<Offset> _points = [];
  List<Offset> _holePoints = [];

  // Flags to track drawing state
  bool _isDrawingHole = false;
  bool _isDrawingPolygon = false;

  // Lists to store completed polygons and holes
  List<Map<String, dynamic>> _polygons = [];
  List<Map<String, dynamic>> _holes = [];

  // Current drawing color and opacity
  Color _currentPolygonColor = Colors.blue;
  double _opacity = 0.3;

  // Storage for favorite colors and all available colors
  final Set<String> _favoriteColors = {};
  Map<String, List<dynamic>> _allColors = {};

  // Image properties
  ui.Image? backgroundImage;
  ui.Image? renderedImage;

  // Position tracking
  Offset? _lastTapPosition;
  int? _selectedPolygonIndex;

  // Undo/redo stacks
  final List<List<Map<String, dynamic>>> _undoStack = [];
  final List<List<Map<String, dynamic>>> _redoStack = [];
  final List<List<Map<String, dynamic>>> _undoHolesStack = [];
  final List<List<Map<String, dynamic>>> _redoHolesStack = [];

  // Add a GlobalKey for the canvas
  final GlobalKey _canvasKey = GlobalKey();

  // Showcase Keys
  final GlobalKey _addImageKey = GlobalKey();
  final GlobalKey _addPolygonKey = GlobalKey();
  final GlobalKey _finishPolygonKey = GlobalKey();
  final GlobalKey _canvasShowcaseKey = GlobalKey();
  final GlobalKey _wallsKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _holeKey = GlobalKey();
  final GlobalKey _magicFillKey = GlobalKey();

  // Add this property to store current color data
  Map<String, dynamic>? _currentColorData;

  bool _isLoading = false;
  bool _isMagicFillMode = false;
  img.Image? _cachedImg;

  /// Initializes the state and loads colors and favorites
  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadFavorites();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoritesAndTutorial();
    });
  }

  Future<void> _checkFavoritesAndTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favoriteColors') ?? [];

    if (favorites.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('No Favorite Colors'),
            content: const Text(
                'You need to add some favorite colors before you can start drawing. Please go back and add some colors to your favorites.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      // Check for tutorial
      bool hasShownTutorial = prefs.getBool('hasShownDrawingTutorial') ?? false;
      if (!hasShownTutorial && mounted) {
        ShowCaseWidget.of(context).startShowCase([
          _addImageKey,
          _addPolygonKey,
          _magicFillKey,
          _canvasShowcaseKey,
          _finishPolygonKey,
          _wallsKey,
          _shareKey,
        ]);
        await prefs.setBool('hasShownDrawingTutorial', true);
      } else {
        // Show toast message only if not showing tutorial
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Click the finish button (✓) after each action to see changes'),
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  /// Loads color data from the colors.json file
  Future<void> _loadColors() async {
    try {
      setState(() {
        _allColors = {
          'light': LightColors.colors,
          'medium': MediumColors.colors,
          'dark': DarkColors.colors,
          'SA': SaColors.colors,
          'SV': SvColors.colors,
          'opus': OpusColors.colors,
          'ncs': NcsColors.colors,
          'wood': WoodColors.colors,
        };
      });
    } catch (e) {
      debugPrint('Error loading colors: $e');
    }
  }

  /// Loads favorite colors from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];
      debugPrint('Loaded favorites: $favorites');
      setState(() {
        _favoriteColors.clear();
        _favoriteColors.addAll(favorites);
      });
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Converts a hex color string to a Color object
  Color _getColorFromHex(String hexString) {
    try {
      final hex = hexString.startsWith('#') ? hexString : '#$hexString';
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      debugPrint('Error parsing color $hexString: $e');
      return Colors.black;
    }
  }

  /// Opens the image picker to select a background image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      setState(() {
        backgroundImage = fi.image;
        renderedImage = fi.image;

        // Reset canvas state for the new image
        _polygons.clear();
        _holes.clear();
        _undoStack.clear();
        _redoStack.clear();
        _undoHolesStack.clear();
        _redoHolesStack.clear();
        _points.clear();
        _holePoints.clear();
        _selectedPolygonIndex = null;
        _cachedImg = null;
      });
    }
  }

  /// Shows the walls management dialog
  void _showWallsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Walls'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _polygons.length,
              itemBuilder: (context, index) {
                final polygon = _polygons[index];
                final wallName = polygon['name'] ?? 'Wall ${index + 1}';
                final colorNumber = polygon['colorNumber'] ?? 'Unknown';
                final colorName = polygon['colorName'] ?? 'Unknown';
                final category = polygon['category'] ?? 'Unknown';
                final page = polygon['page'] ?? 'N/A';

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: polygon['color'] as Color,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: wallName),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            _polygons[index]['name'] = value;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _selectedPolygonIndex = index;
                          });
                          Navigator.pop(context);
                          _showColorPicker();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _polygons.removeAt(index);
                            _saveState();
                            // Force rebuild of the canvas
                            _polygons =
                                List<Map<String, dynamic>>.from(_polygons);
                          });
                          // Close the dialog and rebuild the main widget
                          Navigator.pop(context);
                          this.setState(() {});
                        },
                      ),
                    ],
                  ),
                  subtitle: Text(
                      'Color: $colorNumber - $colorName\nCategory: $category, Page: $page'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  /// Saves the current state to the undo stack
  void _saveState() {
    _undoStack.add(_polygons.map((e) => Map<String, dynamic>.from(e)).toList());
    _undoHolesStack
        .add(_holes.map((e) => Map<String, dynamic>.from(e)).toList());
    _redoStack.clear();
    _redoHolesStack.clear();
  }

  /// Finishes the current polygon or hole
  void _finishPolygon() {
    if (_points.length >= 3 || _holePoints.length >= 3) {
      _saveState();
      setState(() {
        if (_isDrawingHole) {
          // Remove temporary hole if exists
          if (_holes.isNotEmpty && _holes.last['isTemporary'] == true) {
            _holes.removeLast();
          }
          _holes.add({
            'points': List<Offset>.from(_holePoints),
            'color': Colors.transparent,
          });
          _holePoints.clear();
          _isDrawingHole = false;
        } else {
          // Remove temporary polygon if exists
          if (_polygons.isNotEmpty && _polygons.last['isTemporary'] == true) {
            _polygons.removeLast();
          }

          // Create a new color with the current opacity
          final newColor = Color.fromARGB(
            (_opacity * 255).round(),
            (_currentPolygonColor.r * 255).round().clamp(0, 255),
            (_currentPolygonColor.g * 255).round().clamp(0, 255),
            (_currentPolygonColor.b * 255).round().clamp(0, 255),
          );

          // Use the stored color data if available
          _polygons.add({
            'points': List<Offset>.from(_points),
            'color': newColor,
            'colorNumber': _currentColorData?['number'] ?? 'Unknown',
            'colorName': _currentColorData?['name'] ?? 'Unknown',
            'category': _currentColorData?['category'] ?? 'Unknown',
            'page': _currentColorData?['page'] ?? 'N/A',
            'name': 'Wall ${_polygons.length + 1}',
          });
          _points.clear();
          _isDrawingPolygon = false;
          // Clear the current color data after using it
          _currentColorData = null;
        }
        // Force rebuild of the canvas
        _polygons = List<Map<String, dynamic>>.from(_polygons);
        _holes = List<Map<String, dynamic>>.from(_holes);

        // Check for hole tutorial
        if (!_isDrawingHole && _polygons.isNotEmpty) {
          _checkHoleTutorial();
        }
      });
    }
  }

  Future<void> _checkHoleTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShownHoleTutorial = prefs.getBool('hasShownHoleTutorial') ?? false;

    if (!hasShownHoleTutorial && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([_holeKey]);
        prefs.setBool('hasShownHoleTutorial', true);
      });
    }
  }

  /// Shows the color picker modal with favorite colors and opacity buttons
  void _showColorPicker() {
    debugPrint('Showing color picker with favorites: $_favoriteColors');

    if (_favoriteColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No favorite colors available. Please add some colors to favorites first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _favoriteColors.length,
                  itemBuilder: (context, index) {
                    final colorNumber = _favoriteColors.elementAt(index);
                    debugPrint('Processing color number: $colorNumber');

                    // Find the color in all color sets
                    Color color = Colors.black;
                    Map<String, dynamic>? colorData;
                    String? foundCategory;

                    // Search through each color category
                    for (var category in _allColors.keys) {
                      final colors = _allColors[category];
                      if (colors != null) {
                        for (var c in colors) {
                          if (c['number'] == colorNumber) {
                            colorData = c;
                            foundCategory = category;
                            break;
                          }
                        }
                        if (colorData != null) break;
                      }
                    }

                    if (colorData != null) {
                      final hexValue = colorData['value']?.toString() ?? '';
                      if (hexValue.isNotEmpty) {
                        color = _getColorFromHex(hexValue);
                        debugPrint(
                            'Found color: $hexValue in category: $foundCategory');
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedPolygonIndex != null) {
                            // Update the selected polygon's color with opacity
                            final newColor = Color.fromARGB(
                              (_opacity * 255).round(),
                              (color.r * 255).round().clamp(0, 255),
                              (color.g * 255).round().clamp(0, 255),
                              (color.b * 255).round().clamp(0, 255),
                            );
                            _polygons[_selectedPolygonIndex!]['color'] =
                                newColor;
                            // Store the color information
                            _polygons[_selectedPolygonIndex!]['colorNumber'] =
                                colorData?['number'];
                            _polygons[_selectedPolygonIndex!]['colorName'] =
                                colorData?['name'];
                            _polygons[_selectedPolygonIndex!]['category'] =
                                foundCategory;
                            _polygons[_selectedPolygonIndex!]['page'] =
                                colorData?['page'];
                            // Force rebuild of the canvas
                            _polygons =
                                List<Map<String, dynamic>>.from(_polygons);
                          } else {
                            // Update the current drawing color and store its information
                            _currentPolygonColor = color;
                            // Store the current color information for use in _finishPolygon
                            _currentColorData = {
                              'number': colorData?['number'],
                              'name': colorData?['name'],
                              'category': foundCategory,
                              'page': colorData?['page'],
                              'value': colorData?['value'],
                            };
                          }
                          _finishPolygon();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Opacity:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [0.1, 0.25, 0.4, 0.55, 0.75, 1.0]
                                .map((opacity) {
                              final isSelected =
                                  (_opacity - opacity).abs() < 0.01;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _opacity = opacity;
                                      if (_selectedPolygonIndex != null) {
                                        // Update the selected polygon's opacity
                                        final currentColor =
                                            _polygons[_selectedPolygonIndex!]
                                                ['color'] as Color;
                                        final newColor = Color.fromARGB(
                                          (opacity * 255).round(),
                                          (currentColor.r * 255).round().clamp(0, 255),
                                          (currentColor.g * 255).round().clamp(0, 255),
                                          (currentColor.b * 255).round().clamp(0, 255),
                                        );
                                        _polygons[_selectedPolygonIndex!]
                                            ['color'] = newColor;
                                        // Force rebuild of the canvas
                                        _polygons =
                                            List<Map<String, dynamic>>.from(
                                                _polygons);
                                      } else {
                                        // Update the current drawing color
                                        _currentPolygonColor = Color.fromARGB(
                                          (opacity * 255).round(),
                                          (_currentPolygonColor.r * 255).round().clamp(0, 255),
                                          (_currentPolygonColor.g * 255).round().clamp(0, 255),
                                          (_currentPolygonColor.b * 255).round().clamp(0, 255),
                                        );
                                      }
                                    });
                                    _finishPolygon();
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${(opacity * 100).round()}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(_opacity * 100).round()}%',
                          onChangeStart: (value) {
                            if (_selectedPolygonIndex != null) {
                              _saveState();
                            }
                          },
                          onChanged: (value) {
                            // Update the modal state to reflect slider change
                            setModalState(() {
                              _opacity = value;
                            });
                            // Update the parent state to reflect changes on canvas
                            setState(() {
                              _opacity = value;
                              if (_selectedPolygonIndex != null) {
                                // Update the selected polygon's opacity
                                final currentColor =
                                    _polygons[_selectedPolygonIndex!]['color']
                                        as Color;
                                final newColor = Color.fromARGB(
                                  (value * 255).round(),
                                  (currentColor.r * 255).round().clamp(0, 255),
                                  (currentColor.g * 255).round().clamp(0, 255),
                                  (currentColor.b * 255).round().clamp(0, 255),
                                );
                                _polygons[_selectedPolygonIndex!]['color'] =
                                    newColor;
                                // Force rebuild of the canvas
                                _polygons =
                                    List<Map<String, dynamic>>.from(_polygons);
                              } else {
                                // Update the current drawing color
                                _currentPolygonColor = Color.fromARGB(
                                  (value * 255).round(),
                                  (_currentPolygonColor.r * 255).round().clamp(0, 255),
                                  (_currentPolygonColor.g * 255).round().clamp(0, 255),
                                  (_currentPolygonColor.b * 255).round().clamp(0, 255),
                                );
                              }
                            });
                          },
                          onChangeEnd: (value) {
                            if (_selectedPolygonIndex == null) {
                              _finishPolygon();
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Starts a new polygon drawing
  void _startNewPolygon() {
    setState(() {
      _isDrawingPolygon = true;
      _isDrawingHole = false;
      _points.clear();
      _holePoints.clear();
    });
  }

  /// Starts drawing a hole in the current polygon
  void _createHole() {
    if (_polygons.isNotEmpty) {
      setState(() {
        _isDrawingHole = true;
        _isDrawingPolygon = false;
        _holePoints.clear();
        // Force rebuild of the canvas
        _polygons = List<Map<String, dynamic>>.from(_polygons);
        _holes = List<Map<String, dynamic>>.from(_holes);
      });
    }
  }

  /// Checks if a point is inside a polygon using ray casting algorithm
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.isEmpty) return false;

    bool c = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        c = !c;
      }
    }
    return c;
  }

  /// Simplifies a polygon using Ramer-Douglas-Peucker-like logic to make edges straighter
  List<Offset> _simplifyPolygon(List<Offset> points, double epsilon) {
    if (points.length <= 2) return points;

    // Find the point with the maximum distance from the line formed by the first and last points
    double maxDistance = 0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(points[i], points[0], points.last);
      if (distance > maxDistance) {
        index = i;
        maxDistance = distance;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (maxDistance > epsilon) {
      List<Offset> left = _simplifyPolygon(points.sublist(0, index + 1), epsilon);
      List<Offset> right = _simplifyPolygon(points.sublist(index), epsilon);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points[0], points.last];
    }
  }

  double _perpendicularDistance(Offset p, Offset start, Offset end) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;

    double mag = math.sqrt(dx * dx + dy * dy);
    if (mag > 0) {
      dx /= mag;
      dy /= mag;
    }

    double pvx = p.dx - start.dx;
    double pvy = p.dy - start.dy;

    double pvdot = dx * pvx + dy * pvy;

    double ax = pvx - pvdot * dx;
    double ay = pvy - pvdot * dy;

    return math.sqrt(ax * ax + ay * ay);
  }

  // Add a method to capture the canvas as an image with embedded color information
  Future<File?> _captureCanvas() async {
    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Create a new image with extra space for color information
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Draw the original image
        final ui.Image originalImage =
            await decodeImageFromList(byteData.buffer.asUint8List());
        canvas.drawImage(originalImage, Offset.zero, Paint());

        // Calculate the height needed for the walls information
        double yOffset = originalImage.height.toDouble();
        const double padding = 20.0;
        const double lineHeight = 30.0;
        const double colorBoxSize = 24.0;

        // Draw white background for the walls information section
        final backgroundRect = Rect.fromLTWH(
          0,
          yOffset,
          originalImage.width.toDouble(),
          (_polygons.isEmpty
                  ? lineHeight * 3
                  : _polygons.length * lineHeight * 3 + lineHeight * 3)
              .toDouble(),
        );
        canvas.drawRect(
          backgroundRect,
          Paint()..color = Colors.white,
        );

        // Draw header
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
        );

        textPainter.text = TextSpan(
          text: 'WALLS INFORMATION:',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(padding, yOffset));
        yOffset += lineHeight * 1.5;

        // Draw divider
        final paint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(padding, yOffset),
          Offset(originalImage.width - padding, yOffset),
          paint,
        );
        yOffset += lineHeight;

        if (_polygons.isEmpty) {
          textPainter.text = TextSpan(
            text: 'No walls have been created in the canvas.',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(padding, yOffset));
        } else {
          // Draw walls information
          for (int i = 0; i < _polygons.length; i++) {
            final wall = _polygons[i];
            final wallName = wall['name'] ?? 'Wall ${i + 1}';
            final colorNumber = wall['colorNumber'] ?? 'Unknown';
            final colorName = wall['colorName'] ?? 'Unknown';
            final category = wall['category'] ?? 'Unknown';
            final page = wall['page'] ?? 'N/A';

            // Draw wall color preview
            final colorBoxRect = Rect.fromLTWH(
              padding,
              yOffset + (lineHeight - colorBoxSize) / 2,
              colorBoxSize,
              colorBoxSize,
            );
            canvas.drawRect(
              colorBoxRect,
              Paint()..color = wall['color'] as Color,
            );
            canvas.drawRect(
              colorBoxRect,
              Paint()
                ..color = Colors.black
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0,
            );

            // Draw wall name and color information
            textPainter.text = TextSpan(
              text: '$wallName - $colorNumber ($colorName)',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
            textPainter.layout();
            textPainter.paint(
                canvas, Offset(padding + colorBoxSize + 10, yOffset));
            yOffset += lineHeight;

            // Draw category and page information
            textPainter.text = TextSpan(
              text: '   Category: $category, Page: $page',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            );
            textPainter.layout();
            textPainter.paint(
                canvas, Offset(padding + colorBoxSize + 10, yOffset));
            yOffset += lineHeight * 1.5;
          }
        }

        // Add background image information if available
        if (backgroundImage != null) {
          textPainter.text = TextSpan(
            text: 'Background image is included in the canvas.',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(padding, yOffset));
        }

        // Create the final image
        final picture = recorder.endRecording();
        final extendedImage = await picture.toImage(
          originalImage.width,
          (yOffset + padding).toInt(),
        );
        final extendedByteData =
            await extendedImage.toByteData(format: ui.ImageByteFormat.png);

        // Save the extended image
        final directory = await getTemporaryDirectory();
        final String imagePath = '${directory.path}/canvas_share.png';
        final File imageFile = File(imagePath);
        await imageFile.writeAsBytes(extendedByteData!.buffer.asUint8List());

        return imageFile;
      }
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
    }
    return null;
  }

  // Update the share method to only share the image
  Future<void> _shareCanvas() async {
    try {
      // Capture the canvas as an image with embedded color information
      File? imageFile = await _captureCanvas();
      if (imageFile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture canvas image')),
        );
        return;
      }

      // Share the image
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imageFile.path)],
          subject: 'Canvas drawing with color information',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing canvas: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share canvas')),
      );
    }
  }

  // Project saving and loading helpers
  Map<String, dynamic> _serializeOffset(Offset offset) =>
      {'dx': offset.dx, 'dy': offset.dy};
  Offset _deserializeOffset(Map<String, dynamic> map) =>
      Offset(map['dx'], map['dy']);

  Map<String, dynamic> _serializePolygon(Map<String, dynamic> polygon) {
    return {
      'points':
          (polygon['points'] as List<Offset>).map(_serializeOffset).toList(),
      'color': (polygon['color'] as Color).toARGB32(),
      'colorNumber': polygon['colorNumber'],
      'colorName': polygon['colorName'],
      'category': polygon['category'],
      'page': polygon['page'],
      'name': polygon['name'],
    };
  }

  Map<String, dynamic> _deserializePolygon(Map<String, dynamic> map) {
    return {
      'points': (map['points'] as List)
          .map((p) => _deserializeOffset(p as Map<String, dynamic>))
          .toList(),
      'color': Color(map['color'] as int),
      'colorNumber': map['colorNumber'],
      'colorName': map['colorName'],
      'category': map['category'],
      'page': map['page'],
      'name': map['name'],
    };
  }

  Map<String, dynamic> _serializeHole(Map<String, dynamic> hole) {
    return {
      'points': (hole['points'] as List<Offset>).map(_serializeOffset).toList(),
      'color': (hole['color'] as Color).toARGB32(),
    };
  }

  Map<String, dynamic> _deserializeHole(Map<String, dynamic> map) {
    return {
      'points': (map['points'] as List)
          .map((p) => _deserializeOffset(p as Map<String, dynamic>))
          .toList(),
      'color': Color(map['color'] as int),
    };
  }

  Future<void> _saveProject() async {
    if (_polygons.isEmpty && backgroundImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save!')),
      );
      return;
    }

    final projectNameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Project'),
        content: TextField(
          controller: projectNameController,
          decoration: const InputDecoration(hintText: 'Enter project name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, projectNameController.text),
              child: const Text('Save')),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getStringList('saved_projects') ?? [];

      String? imagePath;
      if (backgroundImage != null) {
        final byteData =
            await backgroundImage!.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final buffer = byteData.buffer.asUint8List();
          final directory = await getApplicationDocumentsDirectory();
          imagePath =
              '${directory.path}/project_${name}_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(imagePath);
          await file.writeAsBytes(buffer);
        }
      }

      final projectData = {
        'name': name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'imagePath': imagePath,
        'polygons': _polygons.map(_serializePolygon).toList(),
        'holes': _holes.map(_serializeHole).toList(),
      };

      projectsJson.add(jsonEncode(projectData));
      await prefs.setStringList('saved_projects', projectsJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project "$name" saved successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error saving project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save project')),
        );
      }
    }
  }

  void _showSavedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = prefs.getStringList('saved_projects') ?? [];
    final List<Map<String, dynamic>> projects = projectsJson
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    if (projects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved projects found')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved Projects'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ListTile(
                  title: Text(project['name'] ?? 'Untitled'),
                  subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
                          project['timestamp'] ?? 0)
                      .toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      projectsJson.removeAt(index);
                      await prefs.setStringList('saved_projects', projectsJson);
                      if (mounted) {
                        navigator.pop();
                        _showSavedProjects();
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _loadProject(project);
                  },
                );
              },
            ),
          ),
        ),
      );
    }
  }

  Future<void> _loadProject(Map<String, dynamic> projectData) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Deserialize polygons and holes
      final List<dynamic> loadedPolygons = projectData['polygons'] ?? [];
      final List<dynamic> loadedHoles = projectData['holes'] ?? [];

      _polygons = loadedPolygons
          .map((e) => _deserializePolygon(e as Map<String, dynamic>))
          .toList();
      _holes = loadedHoles
          .map((e) => _deserializeHole(e as Map<String, dynamic>))
          .toList();

      // Load image
      final String? imagePath = projectData['imagePath'];
      if (imagePath != null && File(imagePath).existsSync()) {
        final bytes = await File(imagePath).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final fi = await codec.getNextFrame();
        setState(() {
          backgroundImage = fi.image;
          renderedImage = fi.image;
        });
      }

      _saveState(); // Save to undo stack

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project "${projectData['name']}" loaded')),
        );
      }
    } catch (e) {
      debugPrint('Error loading project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load project')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performMagicFill(Offset tapPosition) async {
    if (backgroundImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_cachedImg == null) {
        final ByteData? byteData =
            await backgroundImage!.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;
        _cachedImg = img.decodeImage(byteData.buffer.asUint8List());
      }

      if (_cachedImg == null) return;

      final img.Image decodedImage = _cachedImg!;

      // Convert Screen Space tap to Image Space
      final RenderBox? renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final Size canvasSize = renderBox.size;
      final double imgW = backgroundImage!.width.toDouble();
      final double imgH = backgroundImage!.height.toDouble();
      final double imageAspectRatio = imgW / imgH;
      final double canvasAspectRatio = canvasSize.width / canvasSize.height;

      double scale;
      double dx = 0;
      double dy = 0;

      if (imageAspectRatio > canvasAspectRatio) {
        scale = canvasSize.width / imgW;
        dy = (canvasSize.height - (imgH * scale)) / 2;
      } else {
        scale = canvasSize.height / imgH;
        dx = (canvasSize.width - (imgW * scale)) / 2;
      }

      final double localX = (tapPosition.dx - dx) / scale;
      final double localY = (tapPosition.dy - dy) / scale;

      if (localX < 0 || localX >= imgW || localY < 0 || localY >= imgH) return;

      final int x = localX.toInt();
      final int y = localY.toInt();

      final img.Color seedColor = decodedImage.getPixel(x, y);
      final double sr = seedColor.r.toDouble();
      final double sg = seedColor.g.toDouble();
      final double sb = seedColor.b.toDouble();

      final List<Offset> imageSpacePoints = [];
      const int numRays = 120; // More rays for better precision
      const double threshold = 45.0; // ~90% similarity (sqrt(255^2 * 3) * 0.1)

      for (int i = 0; i < numRays; i++) {
        final double angle = (i * 360 / numRays) * math.pi / 180;
        final double cosA = math.cos(angle);
        final double sinA = math.sin(angle);

        double dist = 0;
        bool edgeFound = false;

        while (!edgeFound) {
          dist += 1; // High precision step
          final int px = (x + dist * cosA).toInt();
          final int py = (y + dist * sinA).toInt();

          if (px < 0 ||
              px >= decodedImage.width ||
              py < 0 ||
              py >= decodedImage.height) {
            imageSpacePoints.add(Offset(
              px.clamp(0, decodedImage.width - 1).toDouble(),
              py.clamp(0, decodedImage.height - 1).toDouble(),
            ));
            edgeFound = true;
            break;
          }

          final img.Color pixelColor = decodedImage.getPixel(px, py);
          final double pr = pixelColor.r.toDouble();
          final double pg = pixelColor.g.toDouble();
          final double pb = pixelColor.b.toDouble();

          final double colorDist = math.sqrt(
              math.pow(sr - pr, 2) + math.pow(sg - pg, 2) + math.pow(sb - pb, 2));

          if (colorDist > threshold) {
            imageSpacePoints.add(Offset(px.toDouble(), py.toDouble()));
            edgeFound = true;
          }

          if (dist > math.max(imgW, imgH)) {
            // Safety break
            imageSpacePoints.add(Offset(px.toDouble(), py.toDouble()));
            edgeFound = true;
          }
        }
      }

      // Convert back to Screen Space
      List<Offset> screenSpacePoints = imageSpacePoints.map((p) {
        return Offset(p.dx * scale + dx, p.dy * scale + dy);
      }).toList();

      // Simplify the polygon to remove zig-zags and make edges straighter
      screenSpacePoints = _simplifyPolygon(screenSpacePoints, 10.0);

      _saveState();
      setState(() {
        _polygons.add({
          'points': screenSpacePoints,
          'color': _currentPolygonColor.withValues(alpha: _opacity),
          'colorNumber': 'Auto',
          'colorName': 'Magic Fill Area',
          'category': 'AI',
          'page': 'N/A',
          'name': 'Area ${_polygons.length + 1}',
        });
        _isMagicFillMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surface filled successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Magic fill error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Undoes the last action
  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _redoStack.add(List<Map<String, dynamic>>.from(_polygons));
        _redoHolesStack.add(List<Map<String, dynamic>>.from(_holes));
        _polygons = _undoStack.removeLast();
        _holes = _undoHolesStack.removeLast();
      });
    }
  }

  /// Redoes the last undone action
  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(List<Map<String, dynamic>>.from(_polygons));
        _undoHolesStack.add(List<Map<String, dynamic>>.from(_holes));
        _polygons = _redoStack.removeLast();
        _holes = _redoHolesStack.removeLast();
      });
    }
  }

  /// Builds the main UI of the drawing canvas
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isEmpty ? null : _redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProject,
            tooltip: 'Save Project',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _showSavedProjects,
            tooltip: 'Open Project',
          ),
          Showcase(
            key: _wallsKey,
            description:
                'Manage your walls: rename, edit color, or delete them',
            child: IconButton(
              icon: const Icon(Icons.view_agenda),
              onPressed: _showWallsDialog,
            ),
          ),
          Showcase(
            key: _addImageKey,
            description: 'Add a background image to your canvas',
            child: IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _pickImage,
            ),
          ),
          Showcase(
            key: _shareKey,
            description: 'Share your masterpiece with others',
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareCanvas,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width,
                  maxHeight: height,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Showcase(
                          key: _canvasShowcaseKey,
                          description:
                              'Tap here to create points for your polygon. Tap on a completed polygon to change its color.',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: RepaintBoundary(
                              key: _canvasKey,
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isDrawingPolygon &&
                                      !_isDrawingHole &&
                                      !_isMagicFillMode) {
                                    final tapPosition = _lastTapPosition;
                                    if (tapPosition != null) {
                                      for (int i = 0;
                                          i < _polygons.length;
                                          i++) {
                                        final polygon = _polygons[i];
                                        final points =
                                            polygon['points'] as List<Offset>;
                                        if (points.isNotEmpty &&
                                            _isPointInPolygon(
                                                tapPosition, points)) {
                                          setState(() {
                                            _selectedPolygonIndex = i;
                                          });
                                          _showColorPicker();
                                          break;
                                        }
                                      }
                                    }
                                  }
                                },
                                onTapDown: (details) {
                                  setState(() {
                                    _lastTapPosition = details.localPosition;
                                    if (_isMagicFillMode) {
                                      _performMagicFill(details.localPosition);
                                    } else if (_isDrawingPolygon ||
                                        _isDrawingHole) {
                                      if (_isDrawingHole) {
                                        _holePoints.add(details.localPosition);
                                        // Force rebuild of hole points
                                        _holePoints =
                                            List<Offset>.from(_holePoints);
                                      } else {
                                        _points.add(details.localPosition);
                                        // Force rebuild of polygon points
                                        _points = List<Offset>.from(_points);
                                      }
                                    }
                                  });
                                },
                                onTapUp: (details) {
                                  // Remove automatic finishing of polygon
                                },
                                onTapCancel: () {
                                  // Remove automatic finishing of polygon
                                },
                                child: CustomPaint(
                                  painter: _DrawingPainter(
                                    backgroundImage: renderedImage,
                                    polygons: _polygons,
                                    holes: _holes,
                                    isDrawingPolygon: _isDrawingPolygon,
                                    isDrawingHole: _isDrawingHole,
                                    currentPolygonColor: _currentPolygonColor,
                                    points: _points,
                                    holePoints: _holePoints,
                                  ),
                                  size: Size(width, height),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Showcase(
            key: _addPolygonKey,
            description: 'Start drawing a new polygon',
            child: FloatingActionButton(
              heroTag: 'new',
              onPressed: () {
                setState(() {
                  _startNewPolygon();
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 16),
          Showcase(
            key: _finishPolygonKey,
            description: 'Finish drawing the current polygon',
            child: FloatingActionButton(
              heroTag: 'finish',
              onPressed: () {
                setState(() {
                  _finishPolygon();
                });
              },
              child: const Icon(Icons.check),
            ),
          ),
          const SizedBox(height: 16),
          Showcase(
            key: _magicFillKey,
            description: 'Use Magic Fill to automatically detect wall area',
            child: FloatingActionButton(
              heroTag: 'magic',
              backgroundColor: _isMagicFillMode ? Colors.orange : null,
              onPressed: () {
                if (backgroundImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please add a background image first')),
                  );
                  return;
                }
                setState(() {
                  _isMagicFillMode = !_isMagicFillMode;
                  _isDrawingPolygon = false;
                  _isDrawingHole = false;
                });
                if (_isMagicFillMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tap on a wall to fill it automatically'),
                        duration: Duration(seconds: 2)),
                  );
                }
              },
              child: const Icon(Icons.auto_fix_high),
            ),
          ),
          const SizedBox(height: 16),
          if (_polygons.isNotEmpty)
            Showcase(
              key: _holeKey,
              description: 'Create a hole in the selected polygon',
              child: FloatingActionButton(
                heroTag: 'hole',
                onPressed: () {
                  setState(() {
                    _createHole();
                  });
                },
                child: const Icon(Icons.remove),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter class for rendering the drawing canvas
class _DrawingPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final List<Map<String, dynamic>> polygons;
  final List<Map<String, dynamic>> holes;
  final bool isDrawingPolygon;
  final bool isDrawingHole;
  final Color currentPolygonColor;
  final List<Offset> points;
  final List<Offset> holePoints;
  Matrix4? _imageTransform;

  _DrawingPainter({
    this.backgroundImage,
    required this.polygons,
    required this.holes,
    required this.isDrawingPolygon,
    required this.isDrawingHole,
    required this.currentPolygonColor,
    required this.points,
    required this.holePoints,
  });

  /// Calculates the transformation matrix for the background image
  Matrix4 _calculateImageTransform(Size size) {
    if (backgroundImage == null) return Matrix4.identity();

    final imageAspectRatio = backgroundImage!.width / backgroundImage!.height;
    final canvasAspectRatio = size.width / size.height;

    double scale;
    double dx = 0;
    double dy = 0;

    if (imageAspectRatio > canvasAspectRatio) {
      scale = size.width / backgroundImage!.width;
      dy = (size.height - (backgroundImage!.height * scale)) / 2;
    } else {
      scale = size.height / backgroundImage!.height;
      dx = (size.width - (backgroundImage!.width * scale)) / 2;
    }

    return Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  /// Transforms a point from screen coordinates to image coordinates
  Offset _transformPoint(Offset point, Matrix4 transform) {
    final inverse = Matrix4.identity();
    transform.copyInto(inverse);
    inverse.invert();
    final result = inverse.transform3(vector.Vector3(point.dx, point.dy, 0));
    return Offset(result.x, result.y);
  }

  /// Checks if a point is inside a polygon using ray casting algorithm
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.isEmpty) return false;

    bool c = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        c = !c;
      }
    }
    return c;
  }

  /// Calculates the center point of a list of points
  Offset _calculateCenter(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    double sumX = 0;
    double sumY = 0;
    for (var point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  /// Main painting method that renders all elements on the canvas
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image if present
    if (backgroundImage != null) {
      _imageTransform = _calculateImageTransform(size);
      canvas.transform(_imageTransform!.storage);
      canvas.drawImage(backgroundImage!, Offset.zero, Paint());
      // Note: canvas remains transformed for subsequent drawing
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black;

    // Draw existing polygons with their holes
    for (var polygon in polygons) {
      if (polygon['points'].isNotEmpty) {
        // Create the main polygon path
        final polygonPath = Path();
        final transformedPoints = (polygon['points'] as List<Offset>)
            .map((point) =>
                _transformPoint(point, _imageTransform ?? Matrix4.identity()))
            .toList();
        polygonPath.moveTo(transformedPoints[0].dx, transformedPoints[0].dy);
        for (var i = 1; i < transformedPoints.length; i++) {
          polygonPath.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
        }
        polygonPath.close();

        // Find all holes that belong to this polygon
        final polygonHoles = holes.where((hole) {
          if (hole['points'].isEmpty) return false;
          final holeCenter = _calculateCenter(hole['points'] as List<Offset>);
          // Use raw points (Screen Space) for check, as holeCenter is also in Screen Space
          return _isPointInPolygon(
              holeCenter, polygon['points'] as List<Offset>);
        }).toList();

        // Create the final path by subtracting holes from the polygon
        var finalPath = Path();
        finalPath.addPath(polygonPath, Offset.zero);

        // Subtract holes
        for (var hole in polygonHoles) {
          final holePath = Path();
          final transformedHolePoints = (hole['points'] as List<Offset>)
              .map((point) =>
                  _transformPoint(point, _imageTransform ?? Matrix4.identity()))
              .toList();
          holePath.moveTo(
              transformedHolePoints[0].dx, transformedHolePoints[0].dy);
          for (var i = 1; i < transformedHolePoints.length; i++) {
            holePath.lineTo(
                transformedHolePoints[i].dx, transformedHolePoints[i].dy);
          }
          holePath.close();
          finalPath =
              Path.combine(PathOperation.difference, finalPath, holePath);
        }

        // Draw the filled polygon (holes will be transparent, showing background)
        canvas.drawPath(finalPath, Paint()..color = polygon['color']);
        canvas.drawPath(finalPath, paint);

        // Draw the hole outlines
        for (var hole in polygonHoles) {
          final holePath = Path();
          final transformedHolePoints = (hole['points'] as List<Offset>)
              .map((point) =>
                  _transformPoint(point, _imageTransform ?? Matrix4.identity()))
              .toList();
          holePath.moveTo(
              transformedHolePoints[0].dx, transformedHolePoints[0].dy);
          for (var i = 1; i < transformedHolePoints.length; i++) {
            holePath.lineTo(
                transformedHolePoints[i].dx, transformedHolePoints[i].dy);
          }
          holePath.close();
          canvas.drawPath(holePath, paint);
        }
      }
    }

    // Draw current polygon or hole being drawn
    if (isDrawingPolygon && points.isNotEmpty) {
      final path = Path();
      final transformedPoints = points
          .map((point) =>
              _transformPoint(point, _imageTransform ?? Matrix4.identity()))
          .toList();
      path.moveTo(transformedPoints[0].dx, transformedPoints[0].dy);
      for (var i = 1; i < transformedPoints.length; i++) {
        path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
      }
      if (transformedPoints.length >= 3) {
        path.close();
        canvas.drawPath(path, Paint()..color = currentPolygonColor);
      }
      canvas.drawPath(path, paint);

      // Draw points with larger size and better visibility
      for (var point in transformedPoints) {
        canvas.drawCircle(
          point,
          6.0,
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          point,
          6.0,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    } else if (isDrawingHole && holePoints.isNotEmpty) {
      final path = Path();
      final transformedPoints = holePoints
          .map((point) =>
              _transformPoint(point, _imageTransform ?? Matrix4.identity()))
          .toList();
      path.moveTo(transformedPoints[0].dx, transformedPoints[0].dy);
      for (var i = 1; i < transformedPoints.length; i++) {
        path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
      }
      if (transformedPoints.length >= 3) {
        path.close();
      }
      canvas.drawPath(path, paint);

      // Draw points with larger size and better visibility
      for (var point in transformedPoints) {
        canvas.drawCircle(
          point,
          6.0,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          point,
          6.0,
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }
  }

  /// Determines if the painter needs to repaint
  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.polygons != polygons ||
        oldDelegate.holes != holes ||
        oldDelegate.isDrawingPolygon != isDrawingPolygon ||
        oldDelegate.isDrawingHole != isDrawingHole ||
        oldDelegate.currentPolygonColor != currentPolygonColor ||
        oldDelegate.points != points ||
        oldDelegate.holePoints != holePoints;
  }
}
