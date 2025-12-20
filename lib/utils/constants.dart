import 'package:flutter/material.dart';

class AppConstants {
  // Couleurs
  static const Color primaryColor = Color(0xFF128C7E);
  static const Color secondaryColor = Color(0xFF25D366);
  static const Color backgroundColor = Color(0xFFECE5DD);
  static const Color appBarColor = Color(0xFF075E54);

  // Dimensions
  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;

  // Textes
  static const String appName = 'ChatApp Light';

  // Validations
  static const int minPasswordLength = 6;
  static const int maxMessageLength = 1000;
}

class FirebaseConstants {
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String storageFolder = 'chat_images';
}