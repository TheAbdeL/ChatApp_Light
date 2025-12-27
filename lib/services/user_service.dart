import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service de gestion des utilisateurs
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /* --------------------------------------------------------------------------
   * Récupérer tous les utilisateurs sauf l'utilisateur connecté
   * -------------------------------------------------------------------------- */
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

  /* --------------------------------------------------------------------------
   * Rechercher des utilisateurs par nom (filtrage local)
   * -------------------------------------------------------------------------- */
  Stream<List<UserModel>> searchUsers(
    String query,
    String currentUserId,
  ) {
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      if (query.trim().isEmpty) return users;

      return users.where((user) {
        return user.displayName
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
  }

  /* --------------------------------------------------------------------------
   * Récupérer un utilisateur par son ID (one-shot)
   * -------------------------------------------------------------------------- */
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e, stack) {
      debugPrint(
        '❌ getUserById error: $e\n$stack',
      );
      return null;
    }
  }

  /* --------------------------------------------------------------------------
   * Écoute temps réel d'un utilisateur (présence, avatar, nom, etc.)
   * -------------------------------------------------------------------------- */
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /* --------------------------------------------------------------------------
   * Mettre à jour le statut en ligne / hors ligne
   * -------------------------------------------------------------------------- */
  Future<void> updateOnlineStatus(
    String userId,
    bool isOnline,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
        '❌ updateOnlineStatus error: $e\n$stack',
      );
    }
  }

  /* --------------------------------------------------------------------------
   * (OPTIONNEL MAIS RECOMMANDÉ)
   * Initialiser le statut en ligne à la connexion
   * -------------------------------------------------------------------------- */
  Future<void> setUserOnline(String userId) async {
    await updateOnlineStatus(userId, true);
  }

  /* --------------------------------------------------------------------------
   * (OPTIONNEL MAIS RECOMMANDÉ)
   * Marquer l'utilisateur hors ligne à la déconnexion
   * -------------------------------------------------------------------------- */
  Future<void> setUserOffline(String userId) async {
    await updateOnlineStatus(userId, false);
  }
}
