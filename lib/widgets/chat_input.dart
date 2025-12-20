import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/constants.dart';

/// Widget pour le champ de saisie du chat
class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(File) onSendImage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Envoyer le message texte
  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
      setState(() {
        _isTyping = false;
      });
    }
  }

  /// Sélectionner et envoyer une image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        File imageFile = File(image.path);
        widget.onSendImage(imageFile);
      }
    } catch (e) {
      print('❌ Erreur lors de la sélection de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton image
          IconButton(
            icon: Icon(
              Icons.image,
              color: AppConstants.primaryColor,
            ),
            onPressed: _pickImage,
            tooltip: 'Envoyer une image',
          ),

          // Champ de texte
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  setState(() {
                    _isTyping = value.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          // Bouton envoyer
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: _isTyping
                  ? AppConstants.primaryColor
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _isTyping ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }
}