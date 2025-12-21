import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/user_avatar.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/drawer.dart';
import 'create_group_page.dart';
// group pages removed
/// Page de liste des utilisateurs
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  UserModel? _currentUser;
  bool _isLoading = true;

  final Set<String> _notifiedMessages = {};

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

      if (user != null) {
        _listenForNewMessages(user.uid);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Écouter les nouveaux messages pour afficher les notifications
  void _listenForNewMessages(String currentUserId) async {
    await Future.delayed(const Duration(seconds: 2));

    _chatService.getUserChats(currentUserId).listen((chats) {
      for (var chat in chats) {
        final otherId = chat.participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherId.isEmpty) continue;

        _chatService.getMessages(currentUserId, otherId).listen((messages) {
          if (messages.isEmpty || !mounted) return;

          final lastMessage = messages.first;
          final messageId =
              '${chat.chatId}_${lastMessage.timestamp.millisecondsSinceEpoch}';

          final isFromOther = lastMessage.senderId != currentUserId;
          final isRecent =
              DateTime.now().difference(lastMessage.timestamp).inSeconds < 15;
          final notNotified = !_notifiedMessages.contains(messageId);

          if (isFromOther && isRecent && notNotified) {
            _notifiedMessages.add(messageId);

            final senderId = lastMessage.senderId;

            if (senderId.isNotEmpty) {
              _userService.getUserById(senderId).then((sender) {
                if (sender != null && mounted) {
                  final messageText =
                      lastMessage.text.isEmpty && lastMessage.imageUrl != null
                          ? '📷 Image'
                          : lastMessage.text;

                  NotificationService().showMessageNotification(
                    context,
                    senderName: sender.displayName,
                    messageText: messageText,
                    onTap: () {
                      _navigateToChat(sender);
                    },
                  );

                  debugPrint(
                    '🔔 Notification affichée pour message de ${sender.displayName}',
                  );
                }
              });
            }
          }
        });
      }
    });
  }

  /// Gérer la déconnexion
  Future<void> _handleLogout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();

      if (!mounted) return;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
        body: Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
        body: Center(
          child: Text(
            'Erreur de chargement',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppConstants.appBarColor,
        elevation: 0,
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Bouton Dark Mode
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
              );
            },
          ),

            // Bouton Créer un groupe
            IconButton(
              icon: const Icon(Icons.group_add, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupPage()));
              },
              tooltip: 'Créer un groupe',
            ),

          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: Column(
        children: [
          // groups UI removed
          // Barre de recherche
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
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
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
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
                            color: isDark ? Colors.white70 : Colors.grey[600],
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
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Aucun utilisateur disponible'
                              : 'Aucun résultat trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<UserModel> users = snapshot.data!;

                users.sort((a, b) {
                  if (a.isOnline && !b.isOnline) return -1;
                  if (!a.isOnline && b.isOnline) return 1;
                  return a.displayName.compareTo(b.displayName);
                });

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    UserModel user = users[index];
                    return _buildUserTile(user, isDark);
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
  Widget _buildUserTile(UserModel user, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(26),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: UserAvatar(
          photoUrl: user.photoUrl,
          displayName: user.displayName,
          radius: 28,
          showOnlineIndicator: true,
          isOnline: user.isOnline,
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF2D2D2D),
          ),
        ),
        subtitle: Text(
          user.isOnline
              ? 'En ligne'
              : 'Vu ${Helpers.formatTimestamp(user.lastSeen)}',
          style: TextStyle(
            color: user.isOnline
                ? Colors.green
                : (isDark ? Colors.white60 : Colors.grey[600]),
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