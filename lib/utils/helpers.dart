import 'package:intl/intl.dart';

class Helpers {
  /// Formater le timestamp pour affichage
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'à l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// Formater l'heure pour les messages
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Aujourd'hui - afficher l'heure
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Hier
      return 'Hier ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // Cette semaine - afficher le jour
      return DateFormat('EEEE HH:mm', 'fr_FR').format(dateTime);
    } else {
      // Plus ancien - afficher la date complète
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  /// Valider email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Valider mot de passe
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Générer un chatId unique entre deux utilisateurs
  static String getChatId(String userId1, String userId2) {
    // Use lexicographic ordering to ensure deterministic ID across devices
    return userId1.compareTo(userId2) <= 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}