import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/audio_service_simple.dart';
import '../utils/constants.dart';

/// Widget simple pour afficher un message vocal
class VoiceMessageBubbleSimple extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final AudioServiceSimple audioService;

  const VoiceMessageBubbleSimple({
    super.key,
    required this.message,
    required this.isMe,
    required this.audioService,
  });

  @override
  State<VoiceMessageBubbleSimple> createState() => _VoiceMessageBubbleSimpleState();
}

class _VoiceMessageBubbleSimpleState extends State<VoiceMessageBubbleSimple> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? AppConstants.primaryColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                bottomRight: Radius.circular(widget.isMe ? 4 : 16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton play/pause
                GestureDetector(
                  onTap: () async {
                    if (_isPlaying) {
                      await widget.audioService.stopAudio();
                      setState(() => _isPlaying = false);
                    } else {
                      await widget.audioService.playAudio(widget.message.audioUrl!);
                      setState(() => _isPlaying = true);
                      
                      // Auto stop après la durée
                      Future.delayed(
                        Duration(seconds: widget.message.audioDuration ?? 0),
                        () {
                          if (mounted) {
                            setState(() => _isPlaying = false);
                          }
                        },
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.white.withOpacity(0.3)
                          : AppConstants.primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? Colors.white : AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Durée
                Text(
                  AudioServiceSimple.formatDuration(
                    widget.message.audioDuration ?? 0,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 8),

                // Icône micro
                Icon(
                  Icons.mic,
                  size: 16,
                  color: widget.isMe ? Colors.white70 : Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}