import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
  final ImagePicker _picker = ImagePicker();
  final List<Offset> _points = [];
  final List<Offset> _holePoints = [];
  bool _isDrawingHole = false;
  bool _isDrawingPolygon = false;
  List<Map<String, dynamic>> _polygons = [];
  List<Map<String, dynamic>> _holes = [];
  Color _currentPolygonColor = Colors.blue;
  double _opacity = 0.1;
  final Set<String> _favoriteColors = {};
  Map<String, List<dynamic>> _allColors = {};
  ui.Image? backgroundImage;
  ui.Image? renderedImage;
  Offset? _lastTapPosition;
  int? _selectedPolygonIndex;

  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadFavorites();
  }

  Future<void> _loadColors() async {
    try {
      final String jsonString =
          await DefaultAssetBundle.of(context).loadString('assets/colors.json');
      setState(() {
        _allColors = Map<String, List<dynamic>>.from(json.decode(jsonString));
      });
    } catch (e) {
      print('Error loading colors: $e');
    }
  }

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

  Color _getColorFromHex(String hexString) {
    try {
      final hex = hexString.startsWith('#') ? hexString : '#$hexString';
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      print('Error parsing color $hexString: $e');
      return Colors.black;
    }
  }

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
                    for (var category in _allColors.keys) {
                      final colorData = _allColors[category]?.firstWhere(
                        (color) => color['number'] == colorNumber,
                        orElse: () => null,
                      );
                      if (colorData != null) {
                        final hexValue = colorData['value']?.toString() ?? '';
                        if (hexValue.isNotEmpty) {
                          color = _getColorFromHex(hexValue);
                          print('Found color: $hexValue');
                          break;
                        }
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
                            print('Updated polygon color to: $newColor');
                          } else {
                            // Update the current drawing color
                            _currentPolygonColor = Color.fromARGB(
                              (_opacity * 255).round(),
                              color.red,
                              color.green,
                              color.blue,
                            );
                            print(
                                'Updated current color to: $_currentPolygonColor');

                            // If we're currently drawing a polygon, update it immediately
                            if (_isDrawingPolygon && _points.length >= 3) {
                              final newColor = Color.fromARGB(
                                (_opacity * 255).round(),
                                color.red,
                                color.green,
                                color.blue,
                              );
                              _polygons.add({
                                'points': List<Offset>.from(_points),
                                'color': newColor,
                              });
                              _points.clear();
                              _isDrawingPolygon = false;
                            }
                          }
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
                  Expanded(
                    child: Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
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
                            print('Updated polygon opacity to: $value');
                          } else {
                            // Update the current drawing color
                            _currentPolygonColor = Color.fromARGB(
                              (value * 255).round(),
                              _currentPolygonColor.red,
                              _currentPolygonColor.green,
                              _currentPolygonColor.blue,
                            );
                            print('Updated current opacity to: $value');

                            // If we're currently drawing a polygon, update it immediately
                            if (_isDrawingPolygon && _points.length >= 3) {
                              final newColor = Color.fromARGB(
                                (value * 255).round(),
                                _currentPolygonColor.red,
                                _currentPolygonColor.green,
                                _currentPolygonColor.blue,
                              );
                              _polygons.add({
                                'points': List<Offset>.from(_points),
                                'color': newColor,
                              });
                              _points.clear();
                              _isDrawingPolygon = false;
                            }
                          }
                        });
                      },
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

  void _startNewPolygon() {
    setState(() {
      _isDrawingPolygon = true;
      _isDrawingHole = false;
      _points.clear();
      _holePoints.clear();
    });
  }

  void _finishPolygon() {
    if (_points.length >= 3) {
      setState(() {
        if (_isDrawingHole) {
          _holes.add({
            'points': List<Offset>.from(_holePoints),
            'color': Colors.transparent,
          });
          _holePoints.clear();
          _isDrawingHole = false;
        } else {
          // Create a new color with the current opacity
          final newColor = Color.fromARGB(
            (_opacity * 255).round(),
            _currentPolygonColor.red,
            _currentPolygonColor.green,
            _currentPolygonColor.blue,
          );
          _polygons.add({
            'points': List<Offset>.from(_points),
            'color': newColor,
          });
          print('Created new polygon with color: $newColor');
          _points.clear();
          _isDrawingPolygon = false;
        }
      });
    }
  }

  void _createHole() {
    if (_polygons.isNotEmpty) {
      setState(() {
        _isDrawingHole = true;
        _isDrawingPolygon = false;
        _holePoints.clear();
      });
    }
  }

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
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImage,
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
                              } else {
                                _points.add(details.localPosition);
                              }
                            }
                          });
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

  Offset _transformPoint(Offset point, Matrix4 transform) {
    final inverse = Matrix4.identity();
    transform.copyInto(inverse);
    inverse.invert();
    final result = inverse.transform3(vector.Vector3(point.dx, point.dy, 0));
    return Offset(result.x, result.y);
  }

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

  @override
  void paint(Canvas canvas, Size size) {
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

        // Draw the filled polygon with holes
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
