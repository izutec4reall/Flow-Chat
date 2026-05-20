import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  static const String _key = 'fontScale';
  double _scale = 1.0;

  static const List<double> options = [0.85, 1.0, 1.15, 1.3];

  double get scale => _scale;
  /// Returns a translation key for the current font size label.
  String get labelKey {
    switch (_scale) {
      case 0.85: return 'fontSmall';
      case 1.0: return 'fontNormal';
      case 1.15: return 'fontLarge';
      case 1.3: return 'fontExtraLarge';
      default: return 'fontNormal';
    }
  }

  FontSizeProvider() {
    _load();
  }

  void setScale(double value) {
    _scale = value;
    _save();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_key) ?? 1.0;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, _scale);
  }
}
