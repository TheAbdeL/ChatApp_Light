import 'package:flutter/material.dart';
import '../services/audio_service_simple.dart';
import '../utils/constants.dart';

/// Widget pour afficher un message vocal
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioServiceSimple _audioService = AudioServiceSimple();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioService.stopAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton play/pause
        GestureDetector(
          onTap: () async {
            if (_isPlaying) {
              await _audioService.stopAudio();
              setState(() => _isPlaying = false);
            } else {
              await _audioService.playAudio(widget.audioUrl);
              setState(() => _isPlaying = true);
              
              // Auto stop après 60 secondes max
              Future.delayed(
                const Duration(seconds: 60),
                () {
                  if (mounted && _isPlaying) {
                    setState(() => _isPlaying = false);
                  }
                },
              );
            }
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withOpacity(0.3)
                  : AppConstants.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isMe ? Colors.white : AppConstants.primaryColor,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Icône micro
        Icon(
          Icons.mic,
          size: 16,
          color: widget.isMe ? Colors.white70 : Colors.grey[600],
        ),

        const SizedBox(width: 4),

        // Texte
        Text(
          'Message vocal',
          style: TextStyle(
            fontSize: 13,
            color: widget.isMe ? Colors.white : Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}