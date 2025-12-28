import 'package:chatapp_light/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // pour Timer
import 'dart:io';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/audio_service_simple.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart'; // pour Helpers.getChatId()
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/user_avatar.dart';
import '../views/color_settings_page.dart';

/// Page de chat privé (Compatible Web + Mobile + Vocal)
class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final AudioServiceSimple _audioService = AudioServiceSimple();
  final ScrollController _scrollController = ScrollController();

  Timer? _typingTimer;
  bool _isOtherUserTyping = false;
  bool _isOnline = false;
  bool _isSendingImage = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _listenToUserStatus();
    _listenToTypingStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioService.dispose();
    _typingTimer?.cancel();

    // Nettoyer le statut de frappe
    String? currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      String chatId = Helpers.getChatId(currentUserId, widget.userId);
      _chatService.clearTypingStatus(chatId, currentUserId);
    }

    super.dispose();
  }

  /// Marquer les messages comme lus
  void _markMessagesAsRead() {
    String? currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      _chatService.markMessagesAsRead(currentUserId, widget.userId);
    }
  }

  /// Écouter le statut de l'utilisateur
  void _listenToUserStatus() {
    _userService.getUserById(widget.userId).then((user) {
      if (user != null && mounted) {
        setState(() {
          _isOnline = user.isOnline;
        });
      }
    });
  }

  /// Écouter le statut de frappe de l'autre utilisateur
  void _listenToTypingStatus() {
    String? currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    String chatId = Helpers.getChatId(currentUserId, widget.userId);

    _chatService.getTypingStatus(chatId, widget.userId).listen((isTyping) {
      if (mounted) {
        setState(() {
          _isOtherUserTyping = isTyping;
        });
      }
    });
  }

  /// Notifier qu'on est en train d'écrire
  void _handleTyping(bool isTyping) {
    String? currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    String chatId = Helpers.getChatId(currentUserId, widget.userId);

    // Annuler le timer précédent
    _typingTimer?.cancel();

    // Mettre à jour le statut
    _chatService.updateTypingStatus(
      chatId: chatId,
      userId: currentUserId,
      isTyping: isTyping,
    );

    // Si en train d'écrire, créer un timer pour arrêter après 3 secondes
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _chatService.updateTypingStatus(
          chatId: chatId,
          userId: currentUserId,
          isTyping: false,
        );
      });
    }
  }

  /// Envoyer un message texte
  Future<void> _sendMessage(String text) async {
    String? currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      _showError('Erreur d\'authentification');
      return;
    }

    String? error = await _chatService.sendMessage(
      senderId: currentUserId,
      receiverId: widget.userId,
      text: text,
    );

    if (error != null && mounted) {
      _showError(error);
    } else {
      _scrollToBottom();
    }
  }

  /// Envoyer une image (Compatible Web + Mobile)
  Future<void> _sendImage(dynamic imageFile) async {
    String? currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      _showError('Erreur d\'authentification');
      return;
    }

    setState(() {
      _isSendingImage = true;
    });

    // Afficher un message de progression
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Envoi de l\'image en cours...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    String? error = await _chatService.sendImageMessage(
      senderId: currentUserId,
      receiverId: widget.userId,
      imageFile: imageFile,
    );

    if (mounted) {
      setState(() {
        _isSendingImage = false;
      });
    }

    // Cacher le snackbar de progression
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (error != null && mounted) {
      _showError(error);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image envoyée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      _scrollToBottom();
    }
  }

  /// Envoyer un message vocal
  Future<void> _sendVoiceMessage(File audioFile, int duration) async {
    String? currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      _showError('Erreur d\'authentification');
      return;
    }

    setState(() {
      _isSendingImage = true;
    });

    // Afficher un message de progression
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Envoi du message vocal...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    String? error = await _chatService.sendVoiceMessage(
      senderId: currentUserId,
      receiverId: widget.userId,
      audioFile: audioFile,
      duration: duration,
    );

    if (mounted) {
      setState(() {
        _isSendingImage = false;
      });
    }

    // Cacher le snackbar de progression
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (error != null && mounted) {
      _showError(error);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Message vocal envoyé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      _scrollToBottom();
    }
  }

  /// Défiler vers le bas
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Afficher une erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Erreur d\'authentification')),
      );
    }

    final primaryColor = Theme.of(context).primaryColor;
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xF31A1A1A) : const Color(0xFFFFF5F0),

      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            // Avatar de l'utilisateur
            UserAvatar(
              photoUrl: widget.userAvatar,
              displayName: widget.userName,
              radius: 18,
              showOnlineIndicator: true,
              isOnline: _isOnline,
            ),
            const SizedBox(width: 12),

            // Nom et statut
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOtherUserTyping
                        ? 'en train d\'écrire...'
                        : (_isOnline ? 'En ligne' : 'Hors ligne'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ColorSettingsPage()),
              );
            },
            tooltip: 'Couleurs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone des messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(currentUserId, widget.userId),
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
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                // Pas de messages
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envoyez un message pour commencer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<MessageModel> messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = messages[index];
                    bool isMe = message.senderId == currentUserId;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      audioService: _audioService,
                      onDelete: isMe ? (messageId) => _deleteMessage(messageId) : null,
                      onEdit: isMe ? (messageId, newText) => _editMessage(messageId, newText) : null,
                    );
                  },
                );
              },
            ),
          ),

          // Indicateur d'envoi d'image/vocal
          if (_isSendingImage)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Envoi en cours...'),
                ],
              ),
            ),

          // Zone de saisie
          ChatInput(
            onSendMessage: _sendMessage,
            onSendImage: _sendImage,
            onSendVoice: _sendVoiceMessage,
            onTypingChanged: _handleTyping,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    String? currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    String? error = await _chatService.deleteMessage(
      senderId: currentUserId,
      receiverId: widget.userId,
      messageId: messageId,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editMessage(String messageId, String newText) async {
    String? currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    String? error = await _chatService.editMessage(
      senderId: currentUserId,
      receiverId: widget.userId,
      messageId: messageId,
      newText: newText,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}