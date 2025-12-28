import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// Écran d'inscription avec photo de profil
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  // Services
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  // État
  bool _isLoading = false;
  dynamic _profileImage; // Peut être File (mobile) ou XFile (web)
  String? _profileImagePath;

  // Clé du formulaire
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  /// Choisir une photo de profil
  Future<void> _pickProfilePhoto() async {
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
                'Choisir une photo',
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
                  _selectImage(fromGallery: true);
                },
              ),

              // Caméra (seulement sur mobile)
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Appareil photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectImage(fromGallery: false);
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Sélectionner une image
  Future<void> _selectImage({required bool fromGallery}) async {
    try {
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

      if (imageFile != null) {
        setState(() {
          _profileImage = imageFile;
          _profileImagePath = kIsWeb ? null : (imageFile as File).path;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Supprimer la photo sélectionnée
  void _removeProfilePhoto() {
    setState(() {
      _profileImage = null;
      _profileImagePath = null;
    });
  }

  /// Fonction d'inscription
  Future<void> _handleRegister() async {
    // Vérifier la validation du formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Créer le compte (sans photo d'abord)
      String? error = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );

      if (error != null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. Si une photo a été sélectionnée, l'uploader
      if (_profileImage != null) {
        String? userId = _authService.currentUser?.uid;
        
        if (userId != null) {  // ✅ CORRECTION ICI
          String? photoUrl = await _storageService.uploadProfileImage(
            userId: userId,
            imageFile: _profileImage,
          );

          if (photoUrl != null) {
            // Mettre à jour le profil avec la photo
            await _authService.updateProfile(
              displayName: _displayNameController.text.trim(),
              photoUrl: photoUrl,
            );
          }
        }  // ✅ FERMETURE DU IF
      }

      setState(() {
        _isLoading = false;
      });

      // Succès
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Inscription réussie ! Vous pouvez vous connecter.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppConstants.appBarColor),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Photo de profil (NOUVEAU)
                  GestureDetector(
                    onTap: _isLoading ? null : _pickProfilePhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profileImage != null
                              ? (kIsWeb
                                  ? null // Web: géré différemment
                                  : FileImage(_profileImage as File) as ImageProvider)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _profileImage == null ? Icons.add_a_photo : Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bouton pour supprimer la photo
                  if (_profileImage != null)
                    TextButton.icon(
                      onPressed: _removeProfilePhoto,
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer la photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Texte explicatif
                  Text(
                    'Photo de profil (optionnel)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.appBarColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Rejoignez ${AppConstants.appName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Champ Nom d'affichage
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'affichage',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      if (value.length < 3) {
                        return 'Le nom doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Champ Confirmation mot de passe
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bouton d'inscription
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.appBarColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'S\'inscrire',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lien retour vers connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Déjà un compte ? '),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            color: AppConstants.appBarColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}