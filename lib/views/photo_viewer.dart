import 'package:flutter/material.dart';

/// Widget pour afficher une photo en plein écran avec zoom
class PhotoViewer extends StatefulWidget {
  final String? photoUrl;
  final String displayName;

  const PhotoViewer({
    super.key,
    required this.photoUrl,
    required this.displayName,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si pas de photo, afficher un avatar avec initiales
    if (widget.photoUrl == null || widget.photoUrl!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.displayName,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Hero(
            tag: 'photo_${widget.photoUrl ?? widget.displayName}',
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.grey[800],
              child: Text(
                _getInitials(widget.displayName),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Afficher la photo en grand avec zoom
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.displayName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: 'photo_${widget.photoUrl}',
            child: Image.network(
              widget.photoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    _getInitials(widget.displayName),
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Obtenir les initiales du nom
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}