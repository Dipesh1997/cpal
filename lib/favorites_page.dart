import 'package:flutter/material.dart';
import 'color_detail_page.dart';
import 'ncscolors.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  Widget build(BuildContext context) {
    return FavoritesContent(
      allColors: allColors,
      favoriteColorNumbers: favoriteColorNumbers,
      onFavoriteToggle: onFavoriteToggle,
    );
  }
}

class FavoritesContent extends StatefulWidget {
  final Map<String, dynamic> allColors;
  final Set<String> favoriteColorNumbers;
  final Function(String) onFavoriteToggle;

  const FavoritesContent({
    super.key,
    required this.allColors,
    required this.favoriteColorNumbers,
    required this.onFavoriteToggle,
  });

  @override
  State<FavoritesContent> createState() => _FavoritesContentState();
}

class _FavoritesContentState extends State<FavoritesContent>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _favoriteColors = [];
  List<Map<String, dynamic>> _woodFavoriteColors = [];
  bool _isLoading = false;
  late TabController _tabController;
  late Map<String, List<dynamic>> _allColorsWithWood;

  // colorNumber -> saved note text
  Map<String, String> _colorNotes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeColors();
    _updateFavoriteColors();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('color_note_'));
    if (mounted) {
      setState(() {
        _colorNotes = {
          for (var k in keys)
            k.replaceFirst('color_note_', ''): prefs.getString(k) ?? '',
        };
      });
    }
  }

  Future<void> _saveNote(String colorNumber, String note) async {
    final prefs = await SharedPreferences.getInstance();
    if (note.trim().isEmpty) {
      await prefs.remove('color_note_$colorNumber');
    } else {
      await prefs.setString('color_note_$colorNumber', note.trim());
    }
    if (mounted) {
      setState(() {
        if (note.trim().isEmpty) {
          _colorNotes.remove(colorNumber);
        } else {
          _colorNotes[colorNumber] = note.trim();
        }
      });
    }
  }

  void _initializeColors() {
    _allColorsWithWood = Map<String, List<dynamic>>.from(widget.allColors);
    if (!_allColorsWithWood.containsKey('asian')) {
      _allColorsWithWood['asian'] = WoodColors.colors;
    }
    if (!_allColorsWithWood.containsKey('ncs')) {
      _allColorsWithWood['ncs'] = NcsColors.colors;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FavoritesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favoriteColorNumbers != widget.favoriteColorNumbers ||
        oldWidget.allColors != widget.allColors) {
      _initializeColors();
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
    List<Map<String, dynamic>> favorites = [];
    List<Map<String, dynamic>> woodFavorites = [];
    Set<String> processedNumbers = {};

    _allColorsWithWood.forEach((category, colors) {
      for (var color in colors) {
        if (color == null ||
            color['number'] == null ||
            color['value'] == null) {
          continue;
        }
        String colorNumber = color['number'].toString();
        if (processedNumbers.contains(colorNumber)) continue;

        if (widget.favoriteColorNumbers.contains(colorNumber)) {
          final colorData = <String, dynamic>{
            ...color,
            'name': color['name'] ?? '',
            'number': colorNumber,
            'value': color['value'],
            'category': category,
          };
          favorites.add(colorData);
          processedNumbers.add(colorNumber);
          if (category == 'asian' || category == 'ncs') {
            woodFavorites.add(colorData);
          }
        }
      }
    });

    if (mounted) {
      setState(() {
        _favoriteColors = favorites;
        _woodFavoriteColors = woodFavorites;
      });
    }
  }

  void _handleFavoriteToggle(String colorNumber) {
    widget.onFavoriteToggle(colorNumber);
  }

  Future<void> _handleRefresh() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      _updateFavoriteColors();
      await _loadNotes();
      await Future.delayed(const Duration(milliseconds: 100));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildColorGrid(List<Map<String, dynamic>> colors) {
    if (colors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No favorite colors yet'),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.80,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final colorNumber = color['number'].toString();
        return _FavoriteColorCard(
          color: color,
          initialNote: _colorNotes[colorNumber] ?? '',
          hexToColor: hexToColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ColorDetailPage(
                  color: {
                    ...color,
                    'tab': color['category'],
                  },
                  onFavoriteToggle: _handleFavoriteToggle,
                  isFavorite: true,
                  allColors: _allColorsWithWood
                      .map((key, value) => MapEntry(key, value)),
                ),
              ),
            );
          },
          onNoteSaved: (note) => _saveNote(colorNumber, note),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Colors'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Favorites'),
              Tab(text: 'Wood Colors'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _buildColorGrid(_favoriteColors),
          ),
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _buildColorGrid(_woodFavoriteColors),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual favorite color card with optional inline note input
// ─────────────────────────────────────────────────────────────────────────────
class _FavoriteColorCard extends StatefulWidget {
  final Map<String, dynamic> color;
  final String initialNote;
  final Color Function(String) hexToColor;
  final VoidCallback onTap;
  final Future<void> Function(String) onNoteSaved;

  const _FavoriteColorCard({
    required this.color,
    required this.initialNote,
    required this.hexToColor,
    required this.onTap,
    required this.onNoteSaved,
  });

  @override
  State<_FavoriteColorCard> createState() => _FavoriteColorCardState();
}

class _FavoriteColorCardState extends State<_FavoriteColorCard> {
  late TextEditingController _noteController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void didUpdateWidget(_FavoriteColorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialNote != widget.initialNote &&
        _noteController.text != widget.initialNote) {
      _noteController.text = widget.initialNote;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    await widget.onNoteSaved(_noteController.text);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.red, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Color swatch – tap to navigate ───────────────
            Expanded(
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.hexToColor(color['value']),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // ── Color name ────────────────────────────────────
            Text(
              color['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            // ── Color number · hex ───────────────────────────
            Text(
              '${color['number']} · ${color['value']}',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // ── Note input row ───────────────────────────────
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSave(),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        hintText: 'Add note…',
                        hintStyle: TextStyle(
                            fontSize: 11, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                              color: Colors.grey[300]!, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                              color: Colors.grey[300]!, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Colors.deepPurple, width: 1.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // ── Save / spinner ───────────────────────────
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: _isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.deepPurple,
                            ),
                            onPressed: _handleSave,
                            tooltip: 'Save note',
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
