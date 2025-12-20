import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/user_avatar.dart';
import 'chat_page.dart';
import 'login_page.dart';

/// Page de liste des utilisateurs
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charger les informations de l'utilisateur connecté
  Future<void> _loadCurrentUser() async {
    User? firebaseUser = _authService.currentUser;

    if (firebaseUser != null) {
      UserModel? user = await _authService.getUserData(firebaseUser.uid);
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Gérer la déconnexion
  Future<void> _handleLogout() async {
    // Afficher une boîte de dialogue de confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.logout();

      // Rediriger vers la page de connexion
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  /// Naviguer vers la page de chat
  void _navigateToChat(UserModel otherUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          userId: otherUser.uid,
          userName: otherUser.displayName,
          userAvatar: otherUser.photoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: const Center(
          child: Text('Erreur de chargement'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.appBarColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discussions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentUser!.displayName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _searchQuery.isEmpty
                  ? _userService.getAllUsers(_currentUser!.uid)
                  : _userService.searchUsers(_searchQuery, _currentUser!.uid),
              builder: (context, snapshot) {
                // État de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  );
                }

                // Erreur
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Pas de données
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.people_outline
                              : Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun utilisateur disponible'
                              : 'Aucun résultat trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<UserModel> users = snapshot.data!;

                // Trier les utilisateurs (en ligne en premier)
                users.sort((a, b) {
                  if (a.isOnline && !b.isOnline) return -1;
                  if (!a.isOnline && b.isOnline) return 1;
                  return a.displayName.compareTo(b.displayName);
                });

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    UserModel user = users[index];

                    return _buildUserTile(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construire une tuile d'utilisateur
  Widget _buildUserTile(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: UserAvatar(
          photoUrl: user.photoUrl,
          displayName: user.displayName,
          radius: 28,
          showOnlineIndicator: true,
          isOnline: user.isOnline,
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user.isOnline
              ? 'En ligne'
              : 'Vu ${Helpers.formatTimestamp(user.lastSeen)}',
          style: TextStyle(
            color: user.isOnline ? Colors.green : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: AppConstants.primaryColor,
          size: 24,
        ),
        onTap: () => _navigateToChat(user),
      ),
    );
  }
}