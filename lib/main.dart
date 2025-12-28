import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/color_provider.dart';
import 'services/auth_service.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
      ],
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
    return Consumer2<ThemeProvider, ColorProvider>(
      builder: (context, themeProvider, colorProvider, child) {
        return MaterialApp(
          title: 'ChatApp Light',
          debugShowCheckedModeBanner: false,

          // Thème Light avec couleur personnalisée
          theme: _buildLightTheme(colorProvider.primaryColor),

          // Thème Dark avec couleur personnalisée
          darkTheme: _buildDarkTheme(colorProvider.primaryColor),

          // Utiliser le thème selon le choix de l'utilisateur
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Page de démarrage
          home: const SplashScreen(),
        );
      },
    );
  }

  /// Construire le thème clair avec couleur personnalisée
  ThemeData _buildLightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFFFF5F0),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: _lightenColor(primaryColor, 0.2),
        surface: Colors.white,
        background: const Color(0xFFFFF5F0),
      ),
      cardColor: Colors.white,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  /// Construire le thème sombre avec couleur personnalisée
  ThemeData _buildDarkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: _lightenColor(primaryColor, 0.2),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
      ),
      cardColor: const Color(0xFF1E1E1E),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  /// Éclaircir une couleur
  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}