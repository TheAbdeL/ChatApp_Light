import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un utilisateur de l'application
class UserModel {
  final String uid;              // Identifiant unique Firebase
  final String email;            // Email de l'utilisateur
  final String displayName;      // Nom d'affichage
  final DateTime createdAt;      // Date de création du compte
  final bool isOnline;           // Statut en ligne / hors ligne
  final DateTime lastSeen;       // Dernière connexion

  /// Constructeur
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.isOnline = false,
    required this.lastSeen,
  });

  /// Créer un UserModel depuis un document Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir le UserModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }
}