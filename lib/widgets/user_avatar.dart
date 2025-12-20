import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget pour afficher l'avatar d'un utilisateur
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppConstants.primaryColor,
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Text(
            _getInitials(displayName),
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.6,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),

        // Indicateur en ligne
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Obtenir les initiales du nom
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';

    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }
}