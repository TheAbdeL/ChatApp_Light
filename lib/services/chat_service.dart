import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/message_model.dart';
import '../utils/helpers.dart';

/// Service de gestion du chat
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

      String chatId = Helpers.getChatId(senderId, receiverId);

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

      print('✅ Message envoyé avec succès');
      return null;
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      return 'Erreur lors de l\'envoi du message';
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
      String chatId = Helpers.getChatId(senderId, receiverId);

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

      print('✅ Image envoyée avec succès');
      return null;
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de l\'image: $e');
      return 'Erreur lors de l\'envoi de l\'image';
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
      print('❌ Erreur lors de l\'upload de l\'image: $e');
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

  /// Récupérer les messages d'un chat
  Stream<List<MessageModel>> getMessages(String senderId, String receiverId) {
    String chatId = Helpers.getChatId(senderId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      String chatId = Helpers.getChatId(senderId, receiverId);

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

      print('✅ Messages marqués comme lus');
    } catch (e) {
      print('❌ Erreur lors du marquage des messages: $e');
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

      print('✅ Message supprimé');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return 'Erreur lors de la suppression';
    }
  }
}