import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de message dans un groupe
class GroupMessageModel {
  final String messageId;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime timestamp;
  final List<String> readBy;

  GroupMessageModel({
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    required this.timestamp,
    required this.readBy,
  });

  /// Créer depuis Firestore
  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return GroupMessageModel(
      messageId: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhoto: data['senderPhoto'],
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  /// Convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
    };
  }
}