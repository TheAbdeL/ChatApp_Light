import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // ✅ CETTE LIGNE
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';  // ✅ CETTE LIGNE
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // ✅ Écouter les changements d'état de l'app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // ✅ Retirer l'observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ Mettre à jour le statut selon l'état de l'app
    final currentUserId = _authService.currentUser?.uid;
    
    if (currentUserId != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          // App au premier plan → En ligne
          debugPrint('📱 App au premier plan → En ligne');
          _authService.setupPresence(currentUserId);
          break;
          
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          // App en arrière-plan ou fermée → Hors ligne
          debugPrint('📱 App en arrière-plan → Hors ligne');
          FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          }).catchError((error) {
            debugPrint('❌ Erreur mise à jour statut: $error');
          });
          break;
          
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ChatApp Light',
          debugShowCheckedModeBanner: false,
          
          // Thème Light (Orange & Blanc)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFF6B35),
            scaffoldBackgroundColor: const Color(0xFFFFF5F0),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFF6B35),
              secondary: const Color(0xFFFF9F66),
              surface: Colors.white,
            ),
            cardColor: Colors.white,
          ),
          
          // Thème Dark (Orange & Noir)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFFF6B35),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFFF6B35),
              secondary: const Color(0xFFFF9F66),
              surface: const Color(0xFF1E1E1E),
            ),
            cardColor: const Color(0xFF1E1E1E),
          ),
          
          // Utiliser le thème selon le choix de l'utilisateur
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Page de démarrage
          home: const SplashScreen(),
        );
      },
    );
  }
}