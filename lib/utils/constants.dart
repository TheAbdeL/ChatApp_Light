import 'package:flutter/material.dart';

/// Constantes de l'application - THÈME ORANGE & BLANC
class AppConstants {
  // ========== COULEURS PRINCIPALES ==========

  static const Color primaryColor = Color(
    0xFFFF6B35,
  ); // Orange vif (au lieu de vert)
  static const Color secondaryColor = Color(
    0xFFFF9F66,
  ); // Orange pastel (au lieu de vert clair)
  static const Color backgroundColor = Color(
    0xFFFFF5F0,
  ); // Blanc cassé orange (au lieu de beige)
  static const Color appBarColor = Color(
    0xFFFF6B35,
  ); // Orange vif (au lieu de vert foncé)

  // ========== COULEURS SUPPLÉMENTAIRES ==========

  static const Color primaryDark = Color(0xFFE85D2F); // Orange foncé
  static const Color primaryLight = Color(0xFFFF8C5A); // Orange clair
  static const Color accentColor = Color(0xFFFFA500); // Orange doré

  static const Color cardColor = Colors.white;

  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF2D2D2D); // Gris très foncé
  static const Color textSecondaryColor = Color(0xFF757575); // Gris moyen
  static const Color textLightColor = Colors.white;

  static const Color appBarTextColor = Colors.white;

  // Couleurs des messages
  static const Color myMessageColor = Color(
    0xFFFF6B35,
  ); // Orange (mes messages)
  static const Color otherMessageColor = Color(
    0xFFF5F5F5,
  ); // Gris très clair (autres)

  // Couleurs d'état
  static const Color onlineColor = Color(0xFF4CAF50); // Vert (en ligne)
  static const Color offlineColor = Color(0xFF9E9E9E); // Gris (hors ligne)
  static const Color errorColor = Color(0xFFE53935); // Rouge
  static const Color successColor = Color(0xFF43A047); // Vert

  static const Color buttonColor = Color(0xFFFF6B35); // Orange
  static const Color buttonTextColor = Colors.white;

  // ========== DIMENSIONS ==========

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 24.0;

  // ========== TAILLES ==========

  static const double avatarRadius = 24.0;
  static const double smallAvatarRadius = 20.0;
  static const double largeAvatarRadius = 32.0;

  static const double iconSize = 24.0;
  static const double smallIconSize = 20.0;
  static const double largeIconSize = 32.0;

  // ========== STYLES DE TEXTE ==========

  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: appBarTextColor,
  );

  static const TextStyle appBarSubtitleStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFFFFFFFF),
    fontWeight: FontWeight.w400,
  );

  static const TextStyle userNameStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle userStatusStyle = TextStyle(
    fontSize: 13,
    color: textSecondaryColor,
  );

  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 15,
    color: textPrimaryColor,
  );

  static const TextStyle timestampStyle = TextStyle(
    fontSize: 11,
    color: textSecondaryColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: buttonTextColor,
  );

  // ========== DÉGRADÉS ==========

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF7F4D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ========== OMBRES ==========

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.grey.withAlpha(38),
      spreadRadius: 1,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0xFFFF6B35).withAlpha(77),
      spreadRadius: 1,
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ========== TEXTES ==========

  static const String appName = 'ChatApp Light';

  // ========== VALIDATIONS ==========

  static const int minPasswordLength = 6;
  static const int maxMessageLength = 1000;
}

/// Constantes Firebase
class FirebaseConstants {
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String storageFolder = 'chat_images';
}

/// Thème Dark Mode - Orange & Noir
class DarkTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color secondaryColor = Color(0xFFFF9F66);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color appBarColor = Color(0xFF1E1E1E);

  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF2C2C2C);

  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFFB0B0B0);
  static const Color textLightColor = Colors.white;

  static const Color appBarTextColor = Colors.white;

  // Messages
  static const Color myMessageColor = Color(0xFFFF6B35);
  static const Color otherMessageColor = Color(0xFF2C2C2C);

  // États
  static const Color onlineColor = Color(0xFF4CAF50);
  static const Color offlineColor = Color(0xFF757575);

  static const Color buttonColor = Color(0xFFFF6B35);
  static const Color buttonTextColor = Colors.white;

  // Bordures et input
  static const Color borderColor = Color(0xFF3A3A3A);
  static const Color inputFillColor = Color(0xFF2C2C2C);
}
