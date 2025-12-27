import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service d'authentification Firebase
class AuthService {
  // Instance Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir l'utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inscription avec email et mot de passe
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Créer le compte Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Récupérer l'utilisateur créé
      User? user = userCredential.user;

      if (user != null) {
        // Créer le modèle utilisateur
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        // Sauvegarder dans Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toFirestore());

        // ✅ Configurer la présence
        await setupPresence(user.uid);

        debugPrint('✅ Utilisateur créé avec succès: ${user.uid}');
        return null; // Pas d'erreur
      }

      return 'Erreur lors de la création du compte';
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs Firebase
      debugPrint('❌ Erreur Firebase Auth: ${e.code}');

      switch (e.code) {
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'weak-password':
          return 'Le mot de passe est trop faible (min 6 caractères)';
        case 'invalid-email':
          return 'Email invalide';
        default:
          return 'Erreur: ${e.message}';
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      return 'Erreur inattendue lors de l\'inscription';
    }
  }

  /// Connexion avec email et mot de passe
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Connexion Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Mettre à jour le statut en ligne
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });

        // ✅ Configurer la présence
        await setupPresence(user.uid);

        debugPrint('✅ Connexion réussie: ${user.uid}');
        return null; // Pas d'erreur
      }

      return 'Erreur lors de la connexion';
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code}');

      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'invalid-email':
          return 'Email invalide';
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect';
        default:
          return 'Erreur: ${e.message}';
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      return 'Erreur inattendue lors de la connexion';
    }
  }

  /// ✅ NOUVEAU : Configurer la présence en temps réel
  Future<void> setupPresence(String userId) async {
    try {
      // Référence au document utilisateur
      final userRef = _firestore.collection('users').doc(userId);

      // Marquer comme en ligne
      await userRef.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Présence configurée pour $userId');
    } catch (e) {
      debugPrint('❌ Erreur configuration présence: $e');
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      User? user = currentUser;

      if (user != null) {
        // Mettre à jour le statut hors ligne
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      // Déconnexion Firebase Auth
      await _auth.signOut();
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
    }
  }

  /// Récupérer les informations d'un utilisateur depuis Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<String?> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      User? user = currentUser;

      if (user == null) {
        return 'Utilisateur non connecté';
      }

      Map<String, dynamic> updates = {'displayName': displayName};

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);

      debugPrint('✅ Profil mis à jour');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du profil: $e');
      return 'Erreur lors de la mise à jour du profil';
    }
  }
}