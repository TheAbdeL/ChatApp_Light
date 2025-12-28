import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_service_simple.dart';
import '../utils/constants.dart';

/// Widget simple pour enregistrer un message vocal
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String audioPath, int duration) onAudioRecorded;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    super.key,
    required this.onAudioRecorded,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioServiceSimple _audioService = AudioServiceSimple();
  
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  /// Animation de pulsation
  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// Démarrer l'enregistrement
  Future<void> _startRecording() async {
    final started = await _audioService.startRecording();
    
    if (started) {
      setState(() => _isRecording = true);
      
      // Timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingDuration++);
        
        // Limite 2 minutes
        if (_recordingDuration >= 120) {
          _stopRecording();
        }
      });
    } else {
      // Erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'enregistrer. Vérifiez les permissions.'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onCancel();
      }
    }
  }

  /// Arrêter et envoyer
  Future<void> _stopRecording() async {
    _timer?.cancel();
    
    final audioPath = await _audioService.stopRecording();
    
    if (audioPath != null && _recordingDuration > 0) {
      widget.onAudioRecorded(audioPath, _recordingDuration);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement trop court'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onCancel();
      }
    }
  }

  /// Annuler
  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _audioService.cancelRecording();
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton annuler
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _cancelRecording,
            tooltip: 'Annuler',
          ),

          const SizedBox(width: 8),

          // Animation rouge
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Durée
          Text(
            AudioServiceSimple.formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(width: 12),

          // Texte
          Expanded(
            child: Text(
              _recordingDuration < 1 
                  ? 'Commencez à parler...'
                  : 'Enregistrement en cours...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Bouton envoyer
          Container(
            decoration: BoxDecoration(
              color: _recordingDuration >= 1
                  ? AppConstants.primaryColor
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _recordingDuration >= 1 ? _stopRecording : null,
              tooltip: 'Envoyer',
            ),
          ),
        ],
      ),
    );
  }
}