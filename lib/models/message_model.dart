import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un message (avec support audio)
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDuration;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;

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
    this.isEdited = false,
    this.editedAt,
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
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isEdited: data['isEdited'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir le MessageModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isEdited': isEdited,
      if (editedAt != null) 'editedAt' : Timestamp.fromDate(editedAt!),
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
    bool? isEdited,
    DateTime? editedAt,
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
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  /// Vérifier si c'est un message vocal
  bool get isVoiceMessage => audioUrl != null && audioUrl!.isNotEmpty;

  /// Vérifier si c'est un message image
  bool get isImageMessage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Vérifier si c'est un message texte uniquement
  bool get isTextOnly => !isVoiceMessage && !isImageMessage;
}