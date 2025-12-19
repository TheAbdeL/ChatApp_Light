import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // ← AJOUTÉ
import 'services/auth_service.dart';
import 'views/login_screen.dart';

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Firebase avec ta config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // ← MODIFIÉ
  );
  
  // Lancer l'application
  runApp(const MyApp());
}

/// Widget principal de l'application
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp Light',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF075E54),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54),
        ),
      ),
      // Écouter l'état d'authentification
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // En cours de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Si connecté
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Accueil'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await AuthService().logout();
                    },
                  ),
                ],
              ),
              body: const Center(
                child: Text('Connecté avec succès !'),
              ),
            );
          }
          
          // Sinon, connexion
          return const LoginScreen();
        },
      ),
    );
  }
}