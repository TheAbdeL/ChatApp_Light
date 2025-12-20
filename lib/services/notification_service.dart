import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/constants.dart';

/// Service pour afficher des notifications in-app avec son
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Jouer le son de notification
  Future<void> _playNotificationSound() async {
    try {
      // Jouer un son système (beep)
      await SystemSound.play(SystemSoundType.alert);

      // Alternative : Jouer un fichier audio personnalisé
      // await _audioPlayer.play(AssetSource('sounds/notification.mp3'));

      debugPrint('🔊 Son de notification joué');
    } catch (e) {
      debugPrint('❌ Erreur son: $e');
    }
  }

  /// Faire vibrer (mobile uniquement)
  Future<void> _vibrate() async {
    try {
      await HapticFeedback.mediumImpact();
      debugPrint('📳 Vibration déclenchée');
    } catch (e) {
      debugPrint('❌ Erreur vibration: $e');
    }
  }

  /// Afficher une notification de nouveau message (VERSION AMÉLIORÉE)
  void showMessageNotification(
    BuildContext context, {
    required String senderName,
    required String messageText,
    required VoidCallback onTap,
  }) {
    // Ne pas afficher si le contexte n'est pas monté
    if (!context.mounted) return;

    // Jouer le son et vibrer
    _playNotificationSound();
    _vibrate();

    // Afficher la notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                // Avatar avec ombre
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    child: Text(
                      senderName[0].toUpperCase(),
                      style: const TextStyle(
                        
                        
                        
                      color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nom avec badge "NOUVEAU"
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(77),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message avec icône
                      Row(
                        children: [
                          const Icon(
                            Icons.message,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              messageText.length > 45
                                  ? '${messageText.substring(0, 45)}...'
                                  : messageText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Icône d'action
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
       backgroundColor: AppConstants.primaryColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        action: SnackBarAction(
          label: '',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.transparent,
          disabledTextColor: Colors.transparent,
        ),
      ),
    );

    debugPrint('🔔 Notification affichée: $senderName - $messageText');
  }

  /// Afficher une notification simple (sans son)
  void showSimpleNotification(
    BuildContext context, {
    required String title,
    required String message,
    Color? backgroundColor,
    IconData? icon,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(message, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF075E54),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Libérer les ressources
  void dispose() {
    _audioPlayer.dispose();
  }
}
