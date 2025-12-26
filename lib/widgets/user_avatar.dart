import 'package:flutter/material.dart';
import '../views/photo_viewer.dart';

/// Widget d'avatar utilisateur avec photo ou initiales (CLIQUABLE)
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;
  final bool isClickable;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 20,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.isClickable = true,
  });

  /// Obtenir les initiales du nom
  String _getInitials() {
    if (displayName.isEmpty) return '?';
    List<String> parts = displayName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Obtenir une couleur basée sur le nom
  Color _getColorFromName() {
    int hash = displayName.hashCode;
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
    ];
    return colors[hash.abs() % colors.length];
  }

  /// Ouvrir le viewer de photo
  void _openPhotoViewer(BuildContext context) {
    if (!isClickable) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewer(
          photoUrl: photoUrl,
          displayName: displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget = Stack(
      children: [
        // Avatar principal avec Hero animation
        Hero(
          tag: 'photo_${photoUrl ?? displayName}',
          child: CircleAvatar(
            radius: radius,
            backgroundColor: _getColorFromName(),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
                    _getInitials(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),

        // Indicateur en ligne (optionnel)
        if (showOnlineIndicator)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.35,
              height: radius * 0.35,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: radius * 0.08,
                ),
              ),
            ),
          ),
      ],
    );

    // Rendre cliquable si isClickable = true
    if (isClickable) {
      return InkWell(
        onTap: () => _openPhotoViewer(context),
        borderRadius: BorderRadius.circular(radius),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}