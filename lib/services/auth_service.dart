import 'package:firebase_auth/firebase_auth.dart';
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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

        print('✅ Utilisateur créé avec succès: ${user.uid}');
        return null; // Pas d'erreur
      }

      return 'Erreur lors de la création du compte';
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs Firebase
      print('❌ Erreur Firebase Auth: ${e.code}');
      
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
      print('❌ Erreur inattendue: $e');
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

        print('✅ Connexion réussie: ${user.uid}');
        return null; // Pas d'erreur
      }

      return 'Erreur lors de la connexion';
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth: ${e.code}');
      
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'invalid-email':
          return 'Email invalide';
        default:
          return 'Erreur: ${e.message}';
      }
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      return 'Erreur inattendue lors de la connexion';
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
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
    }
  }

  /// Récupérer les informations d'un utilisateur depuis Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return null;
    }
  }
}
