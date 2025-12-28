import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour l'indicateur de frappe
class TypingModel {
  final String userId;
  final bool isTyping;
  final DateTime timestamp;

  TypingModel({
    required this.userId,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingModel.fromFirestore(Map<String, dynamic> data) {
    return TypingModel(
      userId: data['userId'] ?? '',
      isTyping: data['isTyping'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'isTyping': isTyping,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}