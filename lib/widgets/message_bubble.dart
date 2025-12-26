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

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    // Détecter et afficher les messages vocaux
    if (message.audioUrl != null && message.audioUrl!.isNotEmpty) {
      return VoiceMessageBubbleSimple(
        message: message,
        isMe: isMe,
        audioService: audioService,
      );
    }

    // Message normal (texte et/ou image)
    return Align(
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
                color: isMe ? AppConstants.primaryColor : Colors.grey[200],
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
}