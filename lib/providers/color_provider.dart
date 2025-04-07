import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider with ChangeNotifier {
  Color _currentColor = Colors.black;
  Set<String> _favoriteColorNumbers = {};
  SharedPreferences? _prefs;

  Color get currentColor => _currentColor;
  Set<String> get favoriteColorNumbers => _favoriteColorNumbers;

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    _favoriteColorNumbers = _prefs?.getStringList('favorites')?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> toggleFavorite(String colorNumber) async {
    if (_favoriteColorNumbers.contains(colorNumber)) {
      _favoriteColorNumbers.remove(colorNumber);
    } else {
      _favoriteColorNumbers.add(colorNumber);
    }
    await _prefs?.setStringList('favorites', _favoriteColorNumbers.toList());
    notifyListeners();
  }

  bool isFavorite(String colorNumber) {
    return _favoriteColorNumbers.contains(colorNumber);
  }
}
