import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le thème (Light/Dark)
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  /// Charger le thème sauvegardé
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement thème: $e');
    }
  }

  /// Basculer entre Light et Dark
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      debugPrint('✅ Thème ${_isDarkMode ? "Dark" : "Light"} sauvegardé');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde thème: $e');
    }
  }

  /// Définir le thème manuellement
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde thème: $e');
    }
  }
}
