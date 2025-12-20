import 'package:flutter/material.dart';
import '../views/splash_screen.dart';
import '../views/login_page.dart';
import '../views/register_page.dart';
import '../views/users_page.dart';
import '../views/chat_page.dart';

/// Gestion des routes de l'application
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String users = '/users';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      
      case users:
        return MaterialPageRoute(builder: (_) => const UsersPage());
      
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => ChatPage(
              userId: args['userId'] as String,
              userName: args['userName'] as String,
              userAvatar: args['userAvatar'] as String?,
            ),
          );
        }
        return _errorRoute();
      
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Page introuvable')),
      ),
    );
  }
}