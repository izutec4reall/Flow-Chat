import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'appLocale';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isRTL => _locale.languageCode == 'ar';

  LocaleProvider() {
    _load();
  }

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('ar'),
  ];

  String get currentLanguageCode => _locale.languageCode;
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'ar': return 'العربية';
      case 'en': default: return 'English';
    }
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _save();
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _locale.languageCode);
  }
}
