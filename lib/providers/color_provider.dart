import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFF128C7E);
  Color _secondaryColor = const Color(0xFF25D366);

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  // Couleurs prédéfinies
  final List<Color> availableColors = [
    const Color(0xFF128C7E), // Vert WhatsApp (défaut)
    const Color(0xFF2196F3), // Bleu
    const Color(0xFF9C27B0), // Violet
    const Color(0xFFE91E63), // Rose
    const Color(0xFFFF5722), // Orange
    const Color(0xFF607D8B), // Gris bleu
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF4CAF50), // Vert
  ];

  ColorProvider() {
    _loadColorPreference();
  }

  /// Charger la couleur sauvegardée
  Future<void> _loadColorPreference() async {
    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('primaryColor');

    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      notifyListeners();
    }
  }

  /// Changer la couleur primaire
  Future<void> changeColor(Color color) async {
    _primaryColor = color;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);

    notifyListeners();
  }
}