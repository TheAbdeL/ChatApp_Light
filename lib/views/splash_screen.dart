import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'users_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Attendre 2 secondes
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Vérifier si l'utilisateur est connecté
    User? user = _authService.currentUser;

    if (user != null) {
      // Utilisateur connecté → aller à la liste des utilisateurs
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UsersPage()),
      );
    } else {
      // Pas connecté → aller à la page de connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.chat_bubble,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),

            // Nom de l'app
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            // Indicateur de chargement
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}