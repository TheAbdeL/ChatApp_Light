import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../services/audio_service_simple.dart';
import '../widgets/voice_message_bubble.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

/// Widget pour afficher une bulle de message
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final AudioServiceSimple audioService;
  final Function(String)? onDelete;
  final Function(String, String)? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.audioService,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Détecter et afficher les messages vocaux
    if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Bulle vocale
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? AppConstants.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: VoiceMessageBubble(
                  audioUrl: message.audioUrl!,
                  isMe: isMe,
                ),
              ),
              const SizedBox(height: 4),
              // Timestamp
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Helpers.formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? Colors.blue : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Message normal (texte et/ou image)
    return GestureDetector(
        onLongPress: isMe ? () => _showMessageOptions(context) : null,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Bulle du message
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: (message.imageUrl != null && message.imageUrl!.isNotEmpty) ? 4 : 16,
                    vertical: (message.imageUrl != null && message.imageUrl!.isNotEmpty) ? 4 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? primaryColor  // Couleur personnalisée
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image si présente
                      if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                        _buildImage(context),

                      // Texte du message
                      if (message.text.isNotEmpty && message.text != '📷 Photo')
                        Padding(
                          padding: EdgeInsets.only(
                            top: (message.imageUrl != null && message.imageUrl!.isNotEmpty) ? 8 : 0,
                            left: (message.imageUrl != null && message.imageUrl!.isNotEmpty) ? 8 : 0,
                            right: (message.imageUrl != null && message.imageUrl!.isNotEmpty) ? 8 : 0,
                            bottom: (message.imageUrl != null && message.imageUrl!.isNotEmpty) ? 4 : 0,
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Horodatage et statut de lecture
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          'modifié',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Text(
                      Helpers.formatMessageTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  /// Construire le widget image
  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageFullScreen(context),
      child: Hero(
        tag: 'image_${message.id}',
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
            maxWidth: 300,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 40, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Afficher l'image en plein écran
  void _showImageFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Télécharger',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité en développement'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'image_${message.id}',
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 60, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.text.isNotEmpty && message.text != '📷 Photo')
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Modifier'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    TextEditingController controller = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Nouveau message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && onEdit != null) {
                onEdit!(message.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete!(message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}