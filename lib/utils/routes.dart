import 'package:flutter/material.dart';
import '../views/splash_screen.dart';
import '../views/login_page.dart';
import '../views/register_page.dart';
import '../views/users_page.dart';
import '../views/chat_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String users = '/users';
  static const String chat = '/chat';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      users: (context) => const UsersPage(),
      // chat nécessite des arguments, donc pas dans les routes nommées
      // On utilisera Navigator.push() avec des arguments
    };
  }

  // Méthode helper pour naviguer vers ChatPage avec arguments
  static void navigateToChat(
      BuildContext context, {
        required String userId,
        required String userName,
        String? userAvatar,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
        ),
      ),
    );
  }
}