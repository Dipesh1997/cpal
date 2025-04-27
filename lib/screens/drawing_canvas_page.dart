import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import '../lightcolors.dart';
import '../mediumcolors.dart';
import '../darkcolors.dart';
import '../sacolors.dart';
import '../svcolors.dart';
import '../opuscolors.dart';
import '../ncscolors.dart';
import '../woodcolors.dart';

/// A class representing a drawing point with its position and paint properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

/// The main drawing canvas page widget that allows users to draw polygons and holes
class DrawingCanvasPage extends StatefulWidget {
  const DrawingCanvasPage({super.key});

  @override
  State<DrawingCanvasPage> createState() => _DrawingCanvasPageState();
}

/// The state class for the drawing canvas page
class _DrawingCanvasPageState extends State<DrawingCanvasPage> {
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
  List<List<Map<String, dynamic>>> _undoStack = [];
  List<List<Map<String, dynamic>>> _redoStack = [];
  List<List<Map<String, dynamic>>> _undoHolesStack = [];
  List<List<Map<String, dynamic>>> _redoHolesStack = [];

  // Add new properties for layers
  List<Map<String, dynamic>> _layers = [];
  int _currentLayerIndex = 0;

  // Add a GlobalKey for the canvas
  final GlobalKey _canvasKey = GlobalKey();

  /// Initializes the state and loads colors and favorites
  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadFavorites();
    // Initialize with a default layer
    _layers.add({
      'name': 'Layer 1',
      'polygons': <Map<String, dynamic>>[],
      'visible': true,
    });
    // Show toast message after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
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
    });
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
      print('Error loading colors: $e');
    }
  }

  /// Loads favorite colors from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favoriteColors') ?? [];
      print('Loaded favorites: $favorites');
      setState(() {
        _favoriteColors.clear();
        _favoriteColors.addAll(favorites);
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  /// Converts a hex color string to a Color object
  Color _getColorFromHex(String hexString) {
    try {
      final hex = hexString.startsWith('#') ? hexString : '#$hexString';
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      print('Error parsing color $hexString: $e');
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
      });
    }
  }

  /// Shows the layers dialog
  void _showLayersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Polygon Layers'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _layers.length,
              itemBuilder: (context, index) {
                final layer = _layers[index];
                final polygonCount = (layer['polygons'] as List).length;
                return ListTile(
                  leading: Checkbox(
                    value: layer['visible'],
                    onChanged: (value) {
                      setState(() {
                        _layers[index]['visible'] = value;
                        _updateVisibleLayers();
                      });
                    },
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              TextEditingController(text: layer['name']),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            _layers[index]['name'] = value;
                          },
                        ),
                      ),
                      Text(
                        '($polygonCount polygons)',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: () {
                            setState(() {
                              final temp = _layers[index];
                              _layers[index] = _layers[index - 1];
                              _layers[index - 1] = temp;
                              _currentLayerIndex = index - 1;
                              _updateVisibleLayers();
                            });
                          },
                        ),
                      if (index < _layers.length - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: () {
                            setState(() {
                              final temp = _layers[index];
                              _layers[index] = _layers[index + 1];
                              _layers[index + 1] = temp;
                              _currentLayerIndex = index + 1;
                              _updateVisibleLayers();
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          if (_layers.length > 1) {
                            setState(() {
                              _layers.removeAt(index);
                              if (_currentLayerIndex >= _layers.length) {
                                _currentLayerIndex = _layers.length - 1;
                              }
                              _updateVisibleLayers();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  selected: index == _currentLayerIndex,
                  onTap: () {
                    setState(() {
                      _currentLayerIndex = index;
                      _updateVisibleLayers();
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _layers.add({
                    'name': 'Layer ${_layers.length + 1}',
                    'polygons': <Map<String, dynamic>>[],
                    'visible': true,
                  });
                  _currentLayerIndex = _layers.length - 1;
                  _updateVisibleLayers();
                });
                Navigator.pop(context);
              },
              child: const Text('Add Layer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateVisibleLayers() {
    setState(() {
      _polygons = [];
      for (var layer in _layers) {
        if (layer['visible']) {
          _polygons
              .addAll((layer['polygons'] as List).cast<Map<String, dynamic>>());
        }
      }
    });
  }

  /// Saves the current state to the undo stack
  void _saveState() {
    _undoStack.add(List<Map<String, dynamic>>.from(_polygons));
    _undoHolesStack.add(List<Map<String, dynamic>>.from(_holes));
    _redoStack.clear();
    _redoHolesStack.clear();

    // Save current state to the active layer
    if (_currentLayerIndex >= 0 && _currentLayerIndex < _layers.length) {
      _layers[_currentLayerIndex]['polygons'] =
          List<Map<String, dynamic>>.from(_polygons);
    }
  }

  /// Updates the current drawing with the latest state
  void _updateDrawingWithCurrentState() {
    setState(() {
      if (_isDrawingPolygon && _points.length >= 3) {
        // Create a new color with the current opacity
        final newColor = Color.fromARGB(
          (_opacity * 255).round(),
          _currentPolygonColor.red,
          _currentPolygonColor.green,
          _currentPolygonColor.blue,
        );

        // Remove any existing temporary polygon
        if (_polygons.isNotEmpty && _polygons.last['isTemporary'] == true) {
          _polygons.removeLast();
        }

        // Add the new temporary polygon
        _polygons.add({
          'points': List<Offset>.from(_points),
          'color': newColor,
          'isTemporary': true,
        });
        // Force rebuild of the canvas
        _polygons = List<Map<String, dynamic>>.from(_polygons);
        _holes = List<Map<String, dynamic>>.from(_holes);
      } else if (_isDrawingHole && _holePoints.length >= 3) {
        // Remove any existing temporary hole
        if (_holes.isNotEmpty && _holes.last['isTemporary'] == true) {
          _holes.removeLast();
        }

        // Add the new temporary hole
        _holes.add({
          'points': List<Offset>.from(_holePoints),
          'color': Colors.transparent,
          'isTemporary': true,
        });
        // Force rebuild of the canvas
        _polygons = List<Map<String, dynamic>>.from(_polygons);
        _holes = List<Map<String, dynamic>>.from(_holes);
      }
    });
  }

  /// Updates the opacity value and applies it to the current drawing
  void _updateOpacity(double value) {
    setState(() {
      _opacity = value;
      if (_selectedPolygonIndex != null) {
        // Update the selected polygon's opacity
        final currentColor =
            _polygons[_selectedPolygonIndex!]['color'] as Color;
        final newColor = Color.fromARGB(
          (value * 255).round(),
          currentColor.red,
          currentColor.green,
          currentColor.blue,
        );
        _polygons[_selectedPolygonIndex!]['color'] = newColor;
      } else {
        // Update the current drawing color
        _currentPolygonColor = Color.fromARGB(
          (value * 255).round(),
          _currentPolygonColor.red,
          _currentPolygonColor.green,
          _currentPolygonColor.blue,
        );
        // Update any temporary drawing immediately
        if (_isDrawingPolygon && _points.length >= 3) {
          // Remove any existing temporary polygon
          if (_polygons.isNotEmpty && _polygons.last['isTemporary'] == true) {
            _polygons.removeLast();
          }
          // Add the new temporary polygon with updated opacity
          _polygons.add({
            'points': List<Offset>.from(_points),
            'color': _currentPolygonColor,
            'isTemporary': true,
          });
        }
      }
    });
  }

  /// Shows the color picker modal with favorite colors and opacity buttons
  void _showColorPicker() {
    print('Showing color picker with favorites: $_favoriteColors');

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
                    print('Processing color number: $colorNumber');

                    // Find the color in all color sets
                    Color color = Colors.black;
                    Map<String, dynamic>? colorData;

                    // Search through each color category
                    for (var category in _allColors.keys) {
                      final colors = _allColors[category];
                      if (colors != null) {
                        for (var c in colors) {
                          if (c['number'] == colorNumber) {
                            colorData = c;
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
                        print('Found color: $hexValue');
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedPolygonIndex != null) {
                            // Update the selected polygon's color with opacity
                            final newColor = Color.fromARGB(
                              (_opacity * 255).round(),
                              color.red,
                              color.green,
                              color.blue,
                            );
                            _polygons[_selectedPolygonIndex!]['color'] =
                                newColor;
                            // Force rebuild of the canvas
                            _polygons =
                                List<Map<String, dynamic>>.from(_polygons);
                          } else {
                            // Update the current drawing color
                            _currentPolygonColor = Color.fromARGB(
                              (_opacity * 255).round(),
                              color.red,
                              color.green,
                              color.blue,
                            );
                          }
                          _updateDrawingWithCurrentState();
                        });
                        Navigator.pop(context);
                        // Force a UI update after a short delay
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (mounted) {
                            setState(() {
                              _finishPolygon();
                              // Force a rebuild of the canvas
                              _polygons =
                                  List<Map<String, dynamic>>.from(_polygons);
                              _holes = List<Map<String, dynamic>>.from(_holes);
                            });
                          }
                        });
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
                            children: List.generate(10, (index) {
                              final opacity = (index + 1) * 0.1;
                              final isSelected = _opacity == opacity;
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
                                          currentColor.red,
                                          currentColor.green,
                                          currentColor.blue,
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
                                          _currentPolygonColor.red,
                                          _currentPolygonColor.green,
                                          _currentPolygonColor.blue,
                                        );
                                        // Update any temporary drawing
                                        if (_isDrawingPolygon &&
                                            _points.length >= 3) {
                                          _updateDrawingWithCurrentState();
                                        }
                                      }
                                    });
                                    Navigator.pop(context);
                                    // Force a UI update after a short delay
                                    Future.delayed(
                                        const Duration(milliseconds: 50), () {
                                      if (mounted) {
                                        setState(() {
                                          _finishPolygon();
                                          // Force a rebuild of the canvas
                                          _polygons =
                                              List<Map<String, dynamic>>.from(
                                                  _polygons);
                                          _holes =
                                              List<Map<String, dynamic>>.from(
                                                  _holes);
                                        });
                                      }
                                    });
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
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(_opacity * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              _opacity = value;
                              if (_selectedPolygonIndex != null) {
                                // Update the selected polygon's opacity
                                final currentColor =
                                    _polygons[_selectedPolygonIndex!]['color']
                                        as Color;
                                final newColor = Color.fromARGB(
                                  (value * 255).round(),
                                  currentColor.red,
                                  currentColor.green,
                                  currentColor.blue,
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
                                  _currentPolygonColor.red,
                                  _currentPolygonColor.green,
                                  _currentPolygonColor.blue,
                                );
                                // Update any temporary drawing
                                if (_isDrawingPolygon && _points.length >= 3) {
                                  _updateDrawingWithCurrentState();
                                }
                              }
                            });
                          },
                          onChangeEnd: (value) {
                            Navigator.pop(context);
                            // Force a UI update after a short delay
                            Future.delayed(const Duration(milliseconds: 50),
                                () {
                              if (mounted) {
                                setState(() {
                                  _finishPolygon();
                                  // Force a rebuild of the canvas
                                  _polygons = List<Map<String, dynamic>>.from(
                                      _polygons);
                                  _holes =
                                      List<Map<String, dynamic>>.from(_holes);
                                });
                              }
                            });
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
          // Save to current layer
          if (_currentLayerIndex >= 0 && _currentLayerIndex < _layers.length) {
            _layers[_currentLayerIndex]['holes'] =
                List<Map<String, dynamic>>.from(_holes);
          }
        } else {
          // Remove temporary polygon if exists
          if (_polygons.isNotEmpty && _polygons.last['isTemporary'] == true) {
            _polygons.removeLast();
          }
          // Create a new color with the current opacity
          final newColor = Color.fromARGB(
            (_opacity * 255).round(),
            _currentPolygonColor.red,
            _currentPolygonColor.green,
            _currentPolygonColor.blue,
          );

          // Find the color number for the current color
          String? colorNumber;
          for (var category in _allColors.keys) {
            final colors = _allColors[category];
            if (colors != null) {
              for (var color in colors) {
                if (color['value'] != null) {
                  final hexColor = _getColorFromHex(color['value']);
                  if (hexColor.red == _currentPolygonColor.red &&
                      hexColor.green == _currentPolygonColor.green &&
                      hexColor.blue == _currentPolygonColor.blue) {
                    colorNumber = color['number'];
                    break;
                  }
                }
              }
            }
            if (colorNumber != null) break;
          }

          _polygons.add({
            'points': List<Offset>.from(_points),
            'color': newColor,
            'colorNumber': colorNumber, // Store the color number
          });
          _points.clear();
          _isDrawingPolygon = false;
          // Save to current layer
          if (_currentLayerIndex >= 0 && _currentLayerIndex < _layers.length) {
            _layers[_currentLayerIndex]['polygons'] =
                List<Map<String, dynamic>>.from(_polygons);
          }
        }
        // Force rebuild of the canvas
        _polygons = List<Map<String, dynamic>>.from(_polygons);
        _holes = List<Map<String, dynamic>>.from(_holes);
      });
    }
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

        // Collect all unique colors used in polygons
        Set<String> usedColorNumbers = {};
        Map<String, Color> colorMap = {};

        // First pass: collect all colors from polygons
        for (var polygon in _polygons) {
          if (polygon['color'] != null) {
            final Color polygonColor = polygon['color'] as Color;
            // Find matching color from color sets
            for (var category in _allColors.keys) {
              final colors = _allColors[category];
              if (colors != null) {
                for (var color in colors) {
                  if (color['value'] != null) {
                    final hexColor = _getColorFromHex(color['value']);
                    // Compare RGB values (ignoring alpha)
                    if (hexColor.red == polygonColor.red &&
                        hexColor.green == polygonColor.green &&
                        hexColor.blue == polygonColor.blue) {
                      usedColorNumbers.add(color['number']);
                      colorMap[color['number']] = hexColor;
                      break;
                    }
                  }
                }
              }
            }
          }
        }

        // Find color details for each used color
        List<Map<String, dynamic>> colorDetails = [];
        for (var colorNumber in usedColorNumbers) {
          for (var category in _allColors.keys) {
            final colors = _allColors[category];
            if (colors != null) {
              for (var color in colors) {
                if (color['number'] == colorNumber) {
                  colorDetails.add({
                    'number': color['number'],
                    'name': color['name'] ?? 'Unknown',
                    'page': color['page'] ?? 'N/A',
                    'category': category,
                    'value': color['value'] ?? '#000000',
                  });
                  break;
                }
              }
            }
          }
        }

        // Sort color details by category and number
        colorDetails.sort((a, b) {
          int categoryCompare =
              a['category'].toString().compareTo(b['category'].toString());
          if (categoryCompare != 0) return categoryCompare;
          return a['number'].toString().compareTo(b['number'].toString());
        });

        // Draw color information
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
        );

        // Calculate the height needed for the color information
        double yOffset = originalImage.height.toDouble();
        const double padding = 20.0;
        const double lineHeight = 30.0;
        const double colorBoxSize = 24.0;

        // Draw header
        textPainter.text = TextSpan(
          text: 'COLORS USED IN CANVAS:',
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

        if (colorDetails.isEmpty) {
          textPainter.text = TextSpan(
            text: 'No specific colors were used in the canvas.',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(padding, yOffset));
        } else {
          // Draw color information with preview boxes
          for (int i = 0; i < colorDetails.length; i++) {
            final color = colorDetails[i];
            final colorValue = color['value'] as String;
            final previewColor = _getColorFromHex(colorValue);

            // Draw color preview box
            final colorBoxRect = Rect.fromLTWH(
              padding,
              yOffset + (lineHeight - colorBoxSize) / 2,
              colorBoxSize,
              colorBoxSize,
            );
            canvas.drawRect(
              colorBoxRect,
              Paint()..color = previewColor,
            );
            canvas.drawRect(
              colorBoxRect,
              Paint()
                ..color = Colors.black
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0,
            );

            // Draw color number and name
            textPainter.text = TextSpan(
              text: '${i + 1}. ${color['number']} - ${color['name']}',
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

            // Draw category and page
            textPainter.text = TextSpan(
              text: '   Category: ${color['category']}, Page: ${color['page']}',
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
      print('Error capturing canvas: $e');
    }
    return null;
  }

  // Update the share method to only share the image
  Future<void> _shareCanvas() async {
    try {
      // Capture the canvas as an image with embedded color information
      File? imageFile = await _captureCanvas();
      if (imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture canvas image')),
        );
        return;
      }

      // Share the image
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: 'Canvas drawing with color information',
      );
    } catch (e) {
      print('Error sharing canvas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share canvas')),
      );
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
            icon: const Icon(Icons.layers),
            onPressed: _showLayersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareCanvas,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
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
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: GestureDetector(
                          onTap: () {
                            if (!_isDrawingPolygon && !_isDrawingHole) {
                              final tapPosition = _lastTapPosition;
                              if (tapPosition != null) {
                                for (int i = 0; i < _polygons.length; i++) {
                                  final polygon = _polygons[i];
                                  final points =
                                      polygon['points'] as List<Offset>;
                                  if (points.isNotEmpty &&
                                      _isPointInPolygon(tapPosition, points)) {
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
                              if (_isDrawingPolygon || _isDrawingHole) {
                                if (_isDrawingHole) {
                                  _holePoints.add(details.localPosition);
                                  // Force rebuild of hole points
                                  _holePoints = List<Offset>.from(_holePoints);
                                } else {
                                  _points.add(details.localPosition);
                                  // Force rebuild of polygon points
                                  _points = List<Offset>.from(_points);
                                }
                                _updateDrawingWithCurrentState();
                              }
                            });
                          },
                          onTapUp: (details) {
                            if (_isDrawingPolygon || _isDrawingHole) {
                              setState(() {
                                _updateDrawingWithCurrentState();
                              });
                            }
                          },
                          onTapCancel: () {
                            if (_isDrawingPolygon || _isDrawingHole) {
                              setState(() {
                                _updateDrawingWithCurrentState();
                              });
                            }
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
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'new',
            onPressed: () {
              setState(() {
                _startNewPolygon();
              });
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'finish',
            onPressed: () {
              setState(() {
                _finishPolygon();
              });
            },
            child: const Icon(Icons.check),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'hole',
            onPressed: () {
              setState(() {
                _createHole();
              });
            },
            child: const Icon(Icons.remove),
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
      ..translate(dx, dy)
      ..scale(scale);
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
      canvas.transform(Matrix4.identity().storage);
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
          return _isPointInPolygon(holeCenter, transformedPoints);
        }).toList();

        // Create the final path by subtracting holes from the polygon
        var finalPath = Path();
        finalPath.addPath(polygonPath, Offset.zero);

        // Draw the filled polygon with holes
        if (backgroundImage != null) {
          // If there's a background image, draw the polygon with holes
          for (var hole in polygonHoles) {
            final holePath = Path();
            final transformedHolePoints = (hole['points'] as List<Offset>)
                .map((point) => _transformPoint(
                    point, _imageTransform ?? Matrix4.identity()))
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

          // Draw the polygon with holes
          canvas.drawPath(finalPath, Paint()..color = polygon['color']);
          canvas.drawPath(finalPath, paint);

          // Draw the background image through the holes with full opacity
          for (var hole in polygonHoles) {
            final holePath = Path();
            final transformedHolePoints = (hole['points'] as List<Offset>)
                .map((point) => _transformPoint(
                    point, _imageTransform ?? Matrix4.identity()))
                .toList();
            holePath.moveTo(
                transformedHolePoints[0].dx, transformedHolePoints[0].dy);
            for (var i = 1; i < transformedHolePoints.length; i++) {
              holePath.lineTo(
                  transformedHolePoints[i].dx, transformedHolePoints[i].dy);
            }
            holePath.close();

            // Save the current canvas state
            canvas.save();
            // Clip to the hole path
            canvas.clipPath(holePath);
            // Draw the background image with full opacity
            canvas.transform(_imageTransform!.storage);
            canvas.drawImage(backgroundImage!, Offset.zero,
                Paint()..color = Colors.white.withOpacity(1.0));
            canvas.transform(Matrix4.identity().storage);
            // Restore the canvas state
            canvas.restore();
          }
        } else {
          // If no background image, just draw the polygon with transparent holes
          for (var hole in polygonHoles) {
            final holePath = Path();
            final transformedHolePoints = (hole['points'] as List<Offset>)
                .map((point) => _transformPoint(
                    point, _imageTransform ?? Matrix4.identity()))
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
          canvas.drawPath(finalPath, Paint()..color = polygon['color']);
          canvas.drawPath(finalPath, paint);
        }

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
