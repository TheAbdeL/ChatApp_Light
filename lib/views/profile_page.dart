import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/user_avatar.dart';

/// Page de profil utilisateur
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Charger les données utilisateur
  Future<void> _loadUserData() async {
    String? userId = _authService.currentUser?.uid;
    
    if (userId != null) {  // ✅ AJOUT DE LA VÉRIFICATION
      UserModel? user = await _userService.getUserById(userId);
      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Changer la photo de profil
  Future<void> _changeProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Changer la photo de profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Galerie
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _selectAndUploadImage(fromGallery: true);
                },
              ),

              // Caméra (seulement sur mobile)
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Appareil photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectAndUploadImage(fromGallery: false);
                  },
                ),

              // Supprimer la photo
              if (_currentUser?.photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer la photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePhoto();
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Sélectionner et uploader une image
  Future<void> _selectAndUploadImage({required bool fromGallery}) async {
    try {
      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _isUpdating = true;
        });
      }

      // 1. Sélectionner l'image
      dynamic imageFile;

      if (kIsWeb || fromGallery) {
        imageFile = await _storageService.pickImageFromGallery(
          imageQuality: 70,
          maxWidth: 512,
          maxHeight: 512,
        );
      } else {
        imageFile = await _storageService.pickImageFromCamera(
          imageQuality: 70,
          maxWidth: 512,
          maxHeight: 512,
        );
      }

      if (imageFile == null) {
        if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
          setState(() {
            _isUpdating = false;
          });
        }
        return;
      }

      // 2. Uploader vers Firebase Storage
      String? userId = _authService.currentUser?.uid;
      
      if (userId == null) {  // ✅ AJOUT DE LA VÉRIFICATION
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
        return;
      }

      String? photoUrl = await _storageService.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      if (photoUrl == null) {
        throw Exception('Erreur d\'upload');
      }

      // 3. Mettre à jour Firestore
      if (_currentUser != null) {  // ✅ AJOUT DE LA VÉRIFICATION
        await _authService.updateProfile(
          displayName: _currentUser!.displayName,
          photoUrl: photoUrl,
        );
      }

      // 4. Recharger les données
      await _loadUserData();

      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _isUpdating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo de profil mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _isUpdating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Supprimer la photo de profil
  Future<void> _removeProfilePhoto() async {
    try {
      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _isUpdating = true;
        });
      }

      // Vérifier que _currentUser existe
      if (_currentUser == null) {  // ✅ AJOUT DE LA VÉRIFICATION
        throw Exception('Utilisateur non trouvé');
      }

      // Mettre à jour avec photoUrl null
      await _authService.updateProfile(
        displayName: _currentUser!.displayName,
        photoUrl: null,
      );

      // Recharger les données
      await _loadUserData();

      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _isUpdating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo de profil supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {  // ✅ AJOUT DE LA VÉRIFICATION
        setState(() {
          _isUpdating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Déconnexion
  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: AppConstants.appBarColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: AppConstants.appBarColor,
        ),
        body: const Center(
          child: Text('Erreur de chargement du profil'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppConstants.appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec photo de profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppConstants.appBarColor,
              ),
              child: Column(
                children: [
                  // Photo de profil
                  Stack(
                    children: [
                      UserAvatar(
                        photoUrl: _currentUser!.photoUrl,
                        displayName: _currentUser!.displayName,
                        radius: 60,
                      ),
                      if (_isUpdating)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUpdating ? null : _changeProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.appBarColor,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppConstants.appBarColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nom d'affichage
                  Text(
                    _currentUser!.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Text(
                    _currentUser!.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informations du compte
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nom d\'affichage'),
                    subtitle: Text(_currentUser!.displayName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(_currentUser!.email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Membre depuis'),
                    subtitle: Text(
                      '${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: Colors.blue),
                    title: const Text('Changer la photo de profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isUpdating ? null : _changeProfilePhoto,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.red),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}