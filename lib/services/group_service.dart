import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';

/// Service de gestion des groupes
class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un nouveau groupe
  Future<String?> createGroup({
    required String groupName,
    String? groupPhoto,
    required String createdBy,
    required List<String> memberIds,
  }) async {
    try {
      // Ajouter le créateur aux membres
      if (!memberIds.contains(createdBy)) {
        memberIds.add(createdBy);
      }

      DocumentReference groupRef = await _firestore.collection('groups').add({
        'groupName': groupName,
        'groupPhoto': groupPhoto,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'members': memberIds,
        'admins': [createdBy], // Le créateur est admin
      });

      return groupRef.id;
    } catch (e) {
      print('❌ Erreur création groupe: $e');
      return null;
    }
  }

  /// Récupérer tous les groupes d'un utilisateur
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()  // ✅ SUPPRIMÉ orderBy
        .map((snapshot) {
      // ✅ Trier localement
      List<GroupModel> groups = snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
      
      // Trier par date de création (plus récent en premier)
      groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return groups;
    });
  }

  /// Récupérer les infos d'un groupe
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('groups').doc(groupId).get();

      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération groupe: $e');
      return null;
    }
  }

  /// Envoyer un message dans le groupe
  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhoto,
    required String text,
    String? imageUrl,
    String? audioUrl,
  }) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'groupId': groupId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'text': text,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [senderId], // L'envoyeur a lu son propre message
      });
    } catch (e) {
      print('❌ Erreur envoi message groupe: $e');
    }
  }

  /// Récupérer les messages d'un groupe
  Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Marquer un message comme lu
  Future<void> markMessageAsRead(
      String groupId, String messageId, String userId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('❌ Erreur marquage message lu: $e');
    }
  }

  /// Ajouter un membre au groupe
  Future<void> addMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('❌ Erreur ajout membre: $e');
    }
  }

  /// Retirer un membre du groupe
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId]), // Retirer des admins aussi
      });
    } catch (e) {
      print('❌ Erreur retrait membre: $e');
    }
  }

  /// Quitter un groupe
  Future<void> leaveGroup(String groupId, String userId) async {
    await removeMember(groupId, userId);
  }

  /// Mettre à jour le nom du groupe
  Future<void> updateGroupName(String groupId, String newName) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'groupName': newName,
      });
    } catch (e) {
      print('❌ Erreur mise à jour nom: $e');
    }
  }

  /// Mettre à jour la photo du groupe
  Future<void> updateGroupPhoto(String groupId, String? photoUrl) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'groupPhoto': photoUrl,
      });
    } catch (e) {
      print('❌ Erreur mise à jour photo: $e');
    }
  }

  /// Vérifier si un utilisateur est admin
  Future<bool> isAdmin(String groupId, String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('groups').doc(groupId).get();
      
      if (doc.exists) {
        List<String> admins = List<String>.from(doc['admins'] ?? []);
        return admins.contains(userId);
      }
      return false;
    } catch (e) {
      print('❌ Erreur vérification admin: $e');
      return false;
    }
  }
}