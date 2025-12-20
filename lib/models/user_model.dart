import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un utilisateur de l'application
class UserModel {
  final String uid;              // Identifiant unique Firebase
  final String email;            // Email de l'utilisateur
  final String displayName;      // Nom d'affichage
  final String? photoUrl;        // URL de la photo de profil (optionnel)
  final DateTime createdAt;      // Date de création du compte
  final bool isOnline;           // Statut en ligne / hors ligne
  final DateTime lastSeen;       // Dernière connexion

  /// Constructeur
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
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
      photoUrl: data['photoUrl'],
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
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  /// Copier avec modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}