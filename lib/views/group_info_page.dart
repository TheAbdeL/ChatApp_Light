import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../utils/constants.dart';
import '../widgets/user_avatar.dart';

/// Page d'informations du groupe
class GroupInfoPage extends StatefulWidget {
  final GroupModel group;

  const GroupInfoPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();

  String? _currentUserId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Charger les infos utilisateur
  Future<void> _loadUserInfo() async {
    _currentUserId = _authService.currentUser?.uid;
    if (_currentUserId != null) {
      bool admin = await _groupService.isAdmin(widget.group.groupId, _currentUserId!);
      if (mounted) {
        setState(() {
          _isAdmin = admin;
        });
      }
    }
  }

  /// Quitter le groupe
  Future<void> _leaveGroup() async {
    if (_currentUserId == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le groupe'),
        content: const Text('Voulez-vous vraiment quitter ce groupe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _groupService.leaveGroup(widget.group.groupId, _currentUserId!);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppConstants.appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Infos du groupe',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec photo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : AppConstants.appBarColor,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: (widget.group.groupPhoto != null &&
                            widget.group.groupPhoto!.isNotEmpty)
                        ? NetworkImage(widget.group.groupPhoto!)
                        : null,
                    child: (widget.group.groupPhoto == null ||
                            widget.group.groupPhoto!.isEmpty)
                        ? const Icon(Icons.group, color: Colors.orange, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.group.groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.group.members.length} membres',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Membres
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Membres (${widget.group.members.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...widget.group.members.map((memberId) {
                    return FutureBuilder<UserModel?>(
                      future: _userService.getUserById(memberId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        UserModel user = snapshot.data!;
                        bool isAdmin = widget.group.admins.contains(memberId);

                        return ListTile(
                          leading: UserAvatar(
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
                          trailing: isAdmin
                              ? Chip(
                                  label: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppConstants.primaryColor,
                                )
                              : null,
                        );
                      },
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text(
                      'Quitter le groupe',
                      style: TextStyle(color: Colors.red),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _leaveGroup,
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