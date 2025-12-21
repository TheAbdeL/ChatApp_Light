import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../utils/helpers.dart';

/// Service de gestion du chat
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? lastError;

  /// Try to resolve an existing private chatId between two users.
  /// Returns an existing chatId if one exists, otherwise returns the deterministic id.
  Future<String> _resolvePrivateChatId(String userA, String userB) async {
    final deterministic = Helpers.getChatId(userA, userB);
    try {
      final doc = await _firestore.collection('chats').doc(deterministic).get();
      if (doc.exists) return deterministic;

      // Look for any chat where participants contains userA and userB
      final query = await _firestore.collection('chats').where('participants', arrayContains: userA).get();
      for (var d in query.docs) {
        final data = d.data();
        final parts = List<String>.from(data['participants'] ?? []);
        if (parts.contains(userB)) return d.id;
      }
    } catch (e) {
      debugPrint('❌ _resolvePrivateChatId error: $e');
      lastError = e.toString();
    }
    return deterministic;
  }

  /// Envoyer un message texte
  Future<String?> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      if (text.trim().isEmpty) {
        return 'Le message ne peut pas être vide';
      }

      String chatId = await _resolvePrivateChatId(senderId, receiverId);

      // Créer le message
      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Ajouter le message à Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Mettre à jour les métadonnées du chat
      await _updateChatMetadata(chatId, senderId, receiverId, text);

      debugPrint('✅ Message envoyé avec succès');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du message: $e');
      lastError = e.toString();
      return e.toString();
    }
  }

  /// Envoyer un message avec image
  Future<String?> sendImageMessage({
    required String senderId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      String chatId = await _resolvePrivateChatId(senderId, receiverId);

      // Upload l'image vers Firebase Storage
      String? imageUrl = await _uploadImage(imageFile, chatId);

      if (imageUrl == null) {
        return 'Erreur lors de l\'upload de l\'image';
      }

      // Créer le message
      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        text: caption ?? '📷 Photo',
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Ajouter le message à Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Mettre à jour les métadonnées du chat
      await _updateChatMetadata(chatId, senderId, receiverId, '📷 Photo');

      debugPrint('✅ Image envoyée avec succès');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de l\'image: $e');
      lastError = e.toString();
      return e.toString();
    }
  }

  /// Upload une image vers Firebase Storage
  Future<String?> _uploadImage(File imageFile, String chatId) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage
          .ref()
          .child('chat_images')
          .child(chatId)
          .child(fileName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'upload de l\'image: $e');
      lastError = e.toString();
      return null;
    }
  }

  /// Mettre à jour les métadonnées du chat
  Future<void> _updateChatMetadata(
    String chatId,
    String senderId,
    String receiverId,
    String lastMessage,
  ) async {
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    }, SetOptions(merge: true));
  }

  /// Définir le statut de saisie (typing) pour un utilisateur dans un chat
  Future<void> setTyping({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) async {
    try {
      String chatId = await _resolvePrivateChatId(senderId, receiverId);
      await _firestore.collection('chats').doc(chatId).set({
        'typing': {senderId: isTyping},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Erreur setTyping: $e');
      lastError = e.toString();
    }
  }

  /// Stream du document de chat (utile pour écouter le champ `typing`)
  Stream<DocumentSnapshot> getChatDocStream(String senderId, String receiverId) {
    // Return a stream that resolves the correct chat doc dynamically
    final controller = StreamController<DocumentSnapshot>.broadcast();

    () async {
      String chatId = await _resolvePrivateChatId(senderId, receiverId);
      _firestore.collection('chats').doc(chatId).snapshots().listen((s) => controller.add(s));
    }();

    return controller.stream;
  }

  /// Définir le statut de saisie dans un groupe
  Future<void> setGroupTyping({
    required String chatId,
    required String senderId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'typing': {senderId: isTyping},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Erreur setGroupTyping: $e');
      lastError = e.toString();
    }
  }

  /// Récupérer les messages d'un chat
  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) async* {
    String chatId = await _resolvePrivateChatId(senderId, receiverId);

    yield* _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  /// Récupérer les chats d'un utilisateur
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  /// Créer un groupe
  /// Retourne l'id du chat créé en cas de succès, sinon null et `lastError` est renseigné
  Future<String?> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
    File? avatarFile,
  }) async {
    try {
      // Inclure le créateur dans la liste des participants si nécessaire
      final members = Set<String>.from(memberIds)..add(creatorId);

      final docRef = _firestore.collection('chats').doc();
      final chatId = docRef.id;

      await docRef.set({
        'participants': members.toList(),
        'isGroup': true,
        'name': name,
        'admins': [creatorId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (avatarFile != null) {
        final avatarUrl = await _uploadImage(avatarFile, chatId);
        if (avatarUrl != null) {
          await docRef.set({'avatarUrl': avatarUrl}, SetOptions(merge: true));
        }
      }

      return chatId;
    } catch (e) {
      debugPrint('❌ Erreur createGroup: $e');
      lastError = e.toString();
      return null;
    }
  }

  /// Envoyer un message dans un groupe
  Future<String?> sendGroupMessage({
    required String senderId,
    required String chatId,
    required String text,
  }) async {
    try {
      if (text.trim().isEmpty) return 'Le message ne peut pas être vide';

      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: chatId,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('chats').doc(chatId).collection('messages').add(message.toFirestore());

      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      debugPrint('❌ Erreur sendGroupMessage: $e');
      lastError = e.toString();
      return e.toString();
    }
  }

  /// Envoyer une image dans un groupe
  Future<String?> sendGroupImage({
    required String senderId,
    required String chatId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      final imageUrl = await _uploadImage(imageFile, chatId);
      if (imageUrl == null) return 'Erreur lors de l\'upload de l\'image';

      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: chatId,
        text: caption ?? '📷 Photo',
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('chats').doc(chatId).collection('messages').add(message.toFirestore());

      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': caption ?? '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      debugPrint('❌ Erreur sendGroupImage: $e');
      lastError = e.toString();
      return e.toString();
    }
  }

  /// Récupérer les messages d'un groupe par chatId
  Stream<List<MessageModel>> getGroupMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      String chatId = await _resolvePrivateChatId(senderId, receiverId);

      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .get();

      // Marquer tous les messages non lus comme lus
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint('✅ Messages marqués comme lus');
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage des messages: $e');
      lastError = e.toString();
    }
  }

  /// Supprimer un message
  Future<String?> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      debugPrint('✅ Message supprimé');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression: $e');
      lastError = e.toString();
      return e.toString();
    }
  }
  
}
