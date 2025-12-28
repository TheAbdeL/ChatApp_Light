import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
    );
  }
}
