import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  // Group fields
  final bool isGroup;
  final String? name;
  final String? avatarUrl;
  final List<String>? admins;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.isGroup = false,
    this.name,
    this.avatarUrl,
    this.admins,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      isGroup: data['isGroup'] ?? false,
      name: data['name'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      admins: data['admins'] != null ? List<String>.from(data['admins']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'isGroup': isGroup,
      'name': name,
      'avatarUrl': avatarUrl,
      'admins': admins,
    };
  }
}
