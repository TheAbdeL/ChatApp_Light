import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../widgets/voice_recorder_widget.dart';
/// Widget pour le champ de saisie du chat (Image + Vocal)
class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(dynamic) onSendImage;
  final Function(File, int)? onSendVoice;  // ✅ NOUVEAU - Paramètre optionnel

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    this.onSendVoice,  // Optionnel pour ne pas casser le code existant
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final StorageService _storageService = StorageService();
  bool _isTyping = false;
  bool _isUploading = false;
  bool _showVoiceRecorder = false;  // ✅ NOUVEAU - État enregistreur vocal

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Envoyer le message texte
  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty && !_isUploading) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
      setState(() {
        _isTyping = false;
      });
    }
  }

  /// Afficher le sélecteur d'image (Galerie ou Caméra)
  Future<void> _showImageSourceDialog() async {
    // Ne pas afficher si on est sur Web (problème CORS déjà discuté)
    if (kIsWeb) {
      _pickImage(fromGallery: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir une image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Galerie
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromGallery: true);
                },
              ),

              // Caméra
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromGallery: false);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Sélectionner et envoyer une image
  Future<void> _pickImage({required bool fromGallery}) async {
    try {
      setState(() => _isUploading = true);

      dynamic imageFile;
      
      if (kIsWeb) {
        // Sur Web, utiliser directement image_picker
        imageFile = await _storageService.pickImageFromGallery(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else {
        // Sur Mobile
        if (fromGallery) {
          imageFile = await _storageService.pickImageFromGallery(
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1920,
          );
        } else {
          imageFile = await _storageService.pickImageFromCamera(
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1920,
          );
        }
      }

      if (imageFile != null) {
        // Vérifier la taille du fichier (max 5MB) - seulement sur Mobile
        if (!kIsWeb && imageFile is File) {
          bool isTooLarge = await _storageService.isFileTooLarge(imageFile);
          
          if (isTooLarge) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('L\'image est trop volumineuse (max 5MB)'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isUploading = false);
            return;
          }
        }

        // Envoyer l'image
        widget.onSendImage(imageFile);
      }
      
      setState(() => _isUploading = false);
    } catch (e) {
      debugPrint('❌ Erreur lors de la sélection de l\'image: $e');
      setState(() => _isUploading = false);
      
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
    // ✅ NOUVEAU - Afficher l'enregistreur vocal si activé
    if (_showVoiceRecorder) {
      return VoiceRecorderWidget(
        onAudioRecorded: (audioPath, duration) {
          if (widget.onSendVoice != null) {
            widget.onSendVoice!(File(audioPath), duration);
          }
          setState(() => _showVoiceRecorder = false);
        },
        onCancel: () {
          setState(() => _showVoiceRecorder = false);
        },
      );
    }

    // Interface normale
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            icon: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.image, color: AppConstants.primaryColor),
            onPressed: _isUploading ? null : _showImageSourceDialog,
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
                enabled: !_isUploading,
                onChanged: (value) {
                  setState(() {
                    _isTyping = value.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          // ✅ NOUVEAU - Bouton microphone (affiché si pas de texte ET vocal activé)
          if (!_isTyping && !kIsWeb && widget.onSendVoice != null)
            IconButton(
              icon: Icon(Icons.mic, color: AppConstants.primaryColor),
              onPressed: _isUploading 
                  ? null 
                  : () {
                      setState(() => _showVoiceRecorder = true);
                    },
              tooltip: 'Message vocal',
            ),

          // Bouton envoyer (affiché seulement si texte)
          if (_isTyping)
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: !_isUploading
                    ? AppConstants.primaryColor
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: !_isUploading ? _sendMessage : null,
              ),
            ),
        ],
      ),
    );
  }
}