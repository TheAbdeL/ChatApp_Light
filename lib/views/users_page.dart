import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/user_avatar.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'groups_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Page principale avec navigation en bas (Chats / Groupes)
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

  int _selectedIndex = 0; // 0 = Chats, 1 = Groupes

  String _searchQuery = '';
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _activeChatUserId;

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
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }

      if (user != null) {
        _listenForNewMessages(user.uid);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

            if (senderId.isNotEmpty && senderId != _activeChatUserId) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[400]),
            const SizedBox(width: 12),
            Text(
              'Déconnexion',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
  void _navigateToChat(UserModel otherUser) async {
    setState(() {
      _activeChatUserId = otherUser.uid;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          userId: otherUser.uid,
          userName: otherUser.displayName,
          userAvatar: otherUser.photoUrl,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _activeChatUserId = null;
      });
    }
  }

  /// Naviguer vers la page de profil
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ChatApp Light',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _currentUser?.displayName ?? 'Utilisateur',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Bouton Profil
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: _navigateToProfile,
            tooltip: 'Mon profil',
          ),

          // Bouton Dark Mode
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
              );
            },
          ),

          // Bouton de déconnexion
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 20),
            ),
            onPressed: _handleLogout,
            tooltip: 'Déconnexion',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildChatsTab(isDark),
          const GroupsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppConstants.primaryColor,
          unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: 'Groupes',
            ),
          ],
        ),
      ),
    );
  }

  /// Tab des chats privés
  Widget _buildChatsTab(bool isDark) {
    return Column(
      children: [
        // Barre de recherche
        Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(28),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white70 : AppConstants.primaryColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    }
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _searchQuery = value;
                  });
                }
              },
            ),
          ),
        ),

        // Liste des utilisateurs
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _searchQuery.isEmpty
                ? _userService.getAllUsers(_currentUser!.uid)
                : _userService.searchUsers(_searchQuery, _currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppConstants.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement des contacts...',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 80,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vérifiez votre connexion',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty
                            ? Icons.people_outline_rounded
                            : Icons.search_off_rounded,
                        size: 100,
                        color: isDark ? Colors.white38 : Colors.grey[300],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Aucun contact'
                            : 'Aucun résultat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Vos contacts apparaîtront ici'
                            : 'Essayez un autre nom',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey[500],
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
                physics: const BouncingScrollPhysics(),
                itemCount: users.length,
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemBuilder: (context, index) {
                  UserModel user = users[index];
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 200 + (index * 30)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(50 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: _buildUserTile(user, isDark),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Tuile utilisateur avec design moderne
  Widget _buildUserTile(UserModel user, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
              : [Colors.white, const Color(0xFFFFFBF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (user.isOnline ?? false)
              ? Colors.green.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToChat(user),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar avec bordure si en ligne
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (user.isOnline ?? false)
                            ? const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        )
                            : null,
                        boxShadow: [
                          if (user.isOnline ?? false)
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: UserAvatar(
                        photoUrl: user.photoUrl,
                        displayName: user.displayName ?? 'Utilisateur',
                        radius: 28,
                        isClickable: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Nom + statut
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Utilisateur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: (user.isOnline ?? false)
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (user.isOnline ?? false)
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (user.isOnline ?? false)
                                  ? 'En ligne'
                                  : 'Vu ${Helpers.formatTimestamp(user.lastSeen)}',
                              style: TextStyle(
                                color: (user.isOnline ?? false)
                                    ? Colors.green
                                    : (isDark ? Colors.white60 : Colors.grey[600]),
                                fontSize: 13,
                                fontWeight: (user.isOnline ?? false)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icône de chat avec animation
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppConstants.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}