import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/user_avatar.dart';

/// Page de création de groupe
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();
  final StorageService _storageService = StorageService();

  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};

  dynamic _groupImage;
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  /// Sélectionner une photo de groupe
  Future<void> _pickGroupImage() async {
    dynamic image = await _storageService.pickImageFromGallery(
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image != null && mounted) {
      setState(() {
        _groupImage = image;
      });
    }
  }

  /// Créer le groupe
  Future<void> _createGroup() async {
    String groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez entrer un nom de groupe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez sélectionner au moins un membre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      String? currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) throw Exception('Utilisateur non connecté');

      // Upload de la photo de groupe si sélectionnée
      String? groupPhotoUrl;
      if (_groupImage != null) {
        groupPhotoUrl = await _storageService.uploadProfileImage(
          userId: 'group_${DateTime.now().millisecondsSinceEpoch}',
          imageFile: _groupImage,
        );
      }

      // Créer le groupe
      String? groupId = await _groupService.createGroup(
        groupName: groupName,
        groupPhoto: groupPhotoUrl,
        createdBy: currentUserId,
        memberIds: _selectedMemberIds.toList(),
      );

      if (groupId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Groupe créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Erreur de création');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppConstants.appBarColor,
        title: const Text(
          'Créer un groupe',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // En-tête avec photo et nom
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Photo de groupe
                GestureDetector(
                  onTap: _pickGroupImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryColor,
                    backgroundImage: _groupImage != null
                        ? (_groupImage is String
                            ? NetworkImage(_groupImage)
                            : null)
                        : null,
                    child: _groupImage == null
                        ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajouter une photo',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Nom du groupe
                TextField(
                  controller: _groupNameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Nom du groupe',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Titre section membres
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Sélectionner les membres (${_selectedMemberIds.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userService.getAllUsers(currentUserId ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Aucun utilisateur disponible'),
                  );
                }

                List<UserModel> users = snapshot.data!;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    UserModel user = users[index];
                    bool isSelected = _selectedMemberIds.contains(user.uid);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedMemberIds.add(user.uid);
                            } else {
                              _selectedMemberIds.remove(user.uid);
                            }
                          });
                        },
                        secondary: UserAvatar(
                          photoUrl: user.photoUrl,
                          displayName: user.displayName,
                          radius: 24,
                          isClickable: false,
                        ),
                        title: Text(
                          user.displayName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        activeColor: AppConstants.primaryColor,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bouton créer
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Créer le groupe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}