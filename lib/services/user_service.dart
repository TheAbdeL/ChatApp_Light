import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service de gestion des utilisateurs
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer tous les utilisateurs sauf l'utilisateur connecté
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Rechercher des utilisateurs par nom
  Stream<List<UserModel>> searchUsers(String query, String currentUserId) {
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Filtrer par nom (case insensitive)
      if (query.isNotEmpty) {
        users = users.where((user) {
          return user.displayName
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }

      return users;
    });
  }

  /// Récupérer un utilisateur par son ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Mettre à jour le statut en ligne
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut: $e');
    }
  }
}