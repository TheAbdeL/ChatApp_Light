import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../utils/constants.dart';
import '../widgets/group_tile.dart';
import 'create_group_page.dart';
import 'group_chat_page.dart';

/// Page de liste des groupes
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUser?.uid;
  }

  /// Naviguer vers la création de groupe
  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    );
  }

  /// Naviguer vers le chat de groupe
  void _navigateToGroupChat(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatPage(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
        body: const Center(
          child: Text('Erreur: Utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
      body: StreamBuilder<List<GroupModel>>(
        stream: _groupService.getUserGroups(_currentUserId!),
        builder: (context, snapshot) {
          // Chargement
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

          // Pas de groupes
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 80,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun groupe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre premier groupe !',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Liste des groupes
          List<GroupModel> groups = snapshot.data!;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              GroupModel group = groups[index];
              return GroupTile(
                group: group,
                onTap: () => _navigateToGroupChat(group),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGroup,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }
}