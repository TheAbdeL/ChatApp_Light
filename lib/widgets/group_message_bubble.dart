import 'package:flutter/material.dart';
import '../models/group_message_model.dart';
import '../utils/helpers.dart';
import 'voice_message_bubble.dart';  // ✅ AJOUTÉ

/// Bulle de message pour les groupes
class GroupMessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;

  const GroupMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Nom de l'envoyeur (sauf si c'est moi)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo de l'envoyeur
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey,
                      backgroundImage: (message.senderPhoto != null &&
                              message.senderPhoto!.isNotEmpty)
                          ? NetworkImage(message.senderPhoto!)
                          : null,
                      child: (message.senderPhoto == null ||
                              message.senderPhoto!.isEmpty)
                          ? Text(
                              message.senderName.isNotEmpty
                                  ? message.senderName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // Bulle du message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFFFF6B35)
                    : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image si présente
                  if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 100,
                              color: Colors.grey,
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),

                  // Message vocal si présent
                  if (message.audioUrl != null && message.audioUrl!.isNotEmpty)
                    VoiceMessageBubble(
                      audioUrl: message.audioUrl!,
                      isMe: isMe,
                    ),

                  // Texte du message
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontSize: 15,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Timestamp
                  Text(
                    Helpers.formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : (isDark ? Colors.white54 : Colors.black45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}