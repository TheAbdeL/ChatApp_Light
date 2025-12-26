import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../utils/helpers.dart';

/// Service de gestion du chat (Compatible Web + Mobile + Vocal)
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

      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        text: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      await _updateChatMetadata(chatId, senderId, receiverId, text);

      debugPrint('✅ Message envoyé avec succès');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du message: $e');
      return 'Erreur lors de l\'envoi du message';
    }
  }

  /// Envoyer un message avec image (Compatible Web + Mobile)
  Future<String?> sendImageMessage({
    required String senderId,
    required String receiverId,
    required dynamic imageFile, // File pour mobile, XFile pour web
    String? caption,
  }) async {
    try {
      debugPrint('📤 Début envoi image...');
      debugPrint('Type de fichier: ${imageFile.runtimeType}');
      
      String chatId = Helpers.getChatId(senderId, receiverId);

      // Upload l'image vers Firebase Storage
      String? imageUrl = await _uploadImage(imageFile, chatId);

      if (imageUrl == null) {
        debugPrint('❌ URL null après upload');
        return 'Erreur lors de l\'upload de l\'image';
      }

      debugPrint('✅ Image uploadée: $imageUrl');

      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        text: caption ?? '📷 Photo',
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      await _updateChatMetadata(chatId, senderId, receiverId, '📷 Photo');

      debugPrint('✅ Message image sauvegardé dans Firestore');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de l\'image: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return 'Erreur lors de l\'envoi de l\'image: $e';
    }
  }

  /// ✅ NOUVEAU - Envoyer un message vocal
  Future<String?> sendVoiceMessage({
    required String senderId,
    required String receiverId,
    required File audioFile,
    required int duration,
  }) async {
    try {
      debugPrint('📤 Début envoi message vocal...');
      
      String chatId = Helpers.getChatId(senderId, receiverId);

      // Upload l'audio vers Firebase Storage
      String? audioUrl = await _uploadAudio(audioFile, chatId);

      if (audioUrl == null) {
        debugPrint('❌ URL audio null après upload');
        return 'Erreur lors de l\'upload de l\'audio';
      }

      debugPrint('✅ Audio uploadé: $audioUrl');

      // Créer le message
      MessageModel message = MessageModel(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        text: '🎤 Message vocal',
        audioUrl: audioUrl,
        audioDuration: duration,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      await _updateChatMetadata(chatId, senderId, receiverId, '🎤 Message vocal');

      debugPrint('✅ Message vocal sauvegardé dans Firestore');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du message vocal: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return 'Erreur lors de l\'envoi du message vocal: $e';
    }
  }

  /// Upload une image vers Firebase Storage (Compatible Web + Mobile)
  Future<String?> _uploadImage(dynamic imageFile, String chatId) async {
    try {
      debugPrint('🔧 Type reçu: ${imageFile.runtimeType}');
      
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage
          .ref()
          .child('chat_images')
          .child(chatId)
          .child(fileName);

      debugPrint('📁 Chemin Firebase: ${ref.fullPath}');

      UploadTask uploadTask;

      if (kIsWeb) {
        // WEB: imageFile est un XFile
        debugPrint('🌐 Mode Web détecté');
        
        if (imageFile is XFile) {
          final bytes = await imageFile.readAsBytes();
          debugPrint('📊 Taille: ${bytes.length} bytes');
          
          uploadTask = ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          debugPrint('❌ Type inattendu sur Web: ${imageFile.runtimeType}');
          return null;
        }
      } else {
        // MOBILE: imageFile est un File
        debugPrint('📱 Mode Mobile détecté');
        
        if (imageFile is File) {
          uploadTask = ref.putFile(imageFile);
        } else if (imageFile is XFile) {
          // Au cas où XFile est utilisé sur mobile aussi
          final bytes = await imageFile.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else {
          debugPrint('❌ Type inattendu sur Mobile: ${imageFile.runtimeType}');
          return null;
        }
      }

      debugPrint('⏳ Upload en cours...');
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ URL obtenue: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'upload de l\'image: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// ✅ NOUVEAU - Upload un fichier audio vers Firebase Storage
  Future<String?> _uploadAudio(File audioFile, String chatId) async {
    try {
      debugPrint('🔧 Upload audio...');
      
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      Reference ref = _storage
          .ref()
          .child('voice_messages')
          .child(chatId)
          .child(fileName);

      debugPrint('📁 Chemin Firebase: ${ref.fullPath}');

      // Upload avec metadata
      SettableMetadata metadata = SettableMetadata(
        contentType: 'audio/m4a',
        customMetadata: {
          'chatId': chatId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask = ref.putFile(audioFile, metadata);
      
      debugPrint('⏳ Upload audio en cours...');
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ URL audio obtenue: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'upload de l\'audio: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint('✅ Messages marqués comme lus');
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage des messages: $e');
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
      return 'Erreur lors de la suppression';
    }
  }
}