import 'dart:io';
import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/group_message_bubble.dart';
import '../widgets/chat_input.dart';
import 'group_info_page.dart';

/// Page de chat de groupe
class GroupChatPage extends StatefulWidget {
  final GroupModel group;

  const GroupChatPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// Charger l'utilisateur actuel
  Future<void> _loadCurrentUser() async {
    _currentUserId = _authService.currentUser?.uid;
    if (_currentUserId != null) {
      UserModel? user = await _userService.getUserById(_currentUserId!);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }

  /// Envoyer un message texte
  Future<void> _sendMessage(String text) async {
    if (_currentUser == null || _currentUserId == null) return;

    await _groupService.sendMessage(
      groupId: widget.group.groupId,
      senderId: _currentUserId!,
      senderName: _currentUser!.displayName,
      senderPhoto: _currentUser!.photoUrl,
      text: text,
    );
  }

  /// Envoyer une image
  Future<void> _sendImage(dynamic imageFile) async {  // ✅ ACCEPTE LE PARAMÈTRE
    if (_currentUser == null || _currentUserId == null) return;

    try {
      if (imageFile == null) return;  // ✅ VÉRIFICATION

      // Upload vers Storage
      String? imageUrl = await _storageService.uploadGroupImage(
        chatId: widget.group.groupId,
        imageFile: imageFile,
      );

      if (imageUrl != null) {
        // Envoyer le message avec l'image
        await _groupService.sendMessage(
          groupId: widget.group.groupId,
          senderId: _currentUserId!,
          senderName: _currentUser!.displayName,
          senderPhoto: _currentUser!.photoUrl,
          text: '',
          imageUrl: imageUrl,
        );
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
    }
  }

  /// Envoyer un message vocal
  Future<void> _sendVoice(File audioFile, int duration) async {
    if (_currentUser == null || _currentUserId == null) return;

    try {
      String audioPath = audioFile.path;
      
      // Upload vers Storage
      String? audioUrl = await _storageService.uploadVoiceMessage(
        chatId: widget.group.groupId,
        audioPath: audioPath,
      );

      if (audioUrl != null) {
        // Envoyer le message avec l'audio
        await _groupService.sendMessage(
          groupId: widget.group.groupId,
          senderId: _currentUserId!,
          senderName: _currentUser!.displayName,
          senderPhoto: _currentUser!.photoUrl,
          text: '',
          audioUrl: audioUrl,
        );
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
    }
  }

  /// Naviguer vers les infos du groupe
  void _navigateToGroupInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupInfoPage(group: widget.group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppConstants.appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          onTap: _navigateToGroupInfo,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: (widget.group.groupPhoto != null &&
                        widget.group.groupPhoto!.isNotEmpty)
                    ? NetworkImage(widget.group.groupPhoto!)
                    : null,
                child: (widget.group.groupPhoto == null ||
                        widget.group.groupPhoto!.isEmpty)
                    ? const Icon(Icons.group, color: Colors.orange, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.groupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.group.members.length} membres',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _navigateToGroupInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: _groupService.getGroupMessages(widget.group.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<GroupMessageModel> messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    GroupMessageModel message = messages[index];
                    bool isMe = message.senderId == _currentUserId;

                    return GroupMessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // Zone de saisie
          ChatInput(
            onSendMessage: _sendMessage,
            onSendImage: _sendImage,  // ✅ FONCTIONNE MAINTENANT
            onSendVoice: _sendVoice,
            onTypingChanged: (isTyping) {
              // Gérer le typing indicator pour les groupes si nécessaire
              // Sinon laisser vide
            },
          ),
        ],
      ),
    );
  }
}