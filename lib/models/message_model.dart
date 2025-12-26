import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un message (avec support audio)
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final String? audioUrl;      // ✅ NOUVEAU - URL du message vocal
  final int? audioDuration;    // ✅ NOUVEAU - Durée en secondes
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    this.audioDuration,
    required this.timestamp,
    this.isRead = false,
  });

  /// Créer un MessageModel depuis un document Firestore
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],           // ✅ NOUVEAU
      audioDuration: data['audioDuration'], // ✅ NOUVEAU
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  /// Convertir le MessageModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,           // ✅ NOUVEAU
      'audioDuration': audioDuration, // ✅ NOUVEAU
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  /// Copier avec modifications
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? imageUrl,
    String? audioUrl,
    int? audioDuration,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Vérifier si c'est un message vocal
  bool get isVoiceMessage => audioUrl != null && audioUrl!.isNotEmpty;

  /// Vérifier si c'est un message image
  bool get isImageMessage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Vérifier si c'est un message texte uniquement
  bool get isTextOnly => !isVoiceMessage && !isImageMessage;
}