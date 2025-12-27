import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de groupe de chat
class GroupModel {
  final String groupId;
  final String groupName;
  final String? groupPhoto;
  final String createdBy; // ID du créateur
  final DateTime createdAt;
  final List<String> members; // Liste des IDs des membres
  final List<String> admins; // Liste des IDs des admins

  GroupModel({
    required this.groupId,
    required this.groupName,
    this.groupPhoto,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    required this.admins,
  });

  /// Créer un GroupModel depuis Firestore
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return GroupModel(
      groupId: doc.id,
      groupName: data['groupName'] ?? '',
      groupPhoto: data['groupPhoto'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      members: List<String>.from(data['members'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'groupPhoto': groupPhoto,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members,
      'admins': admins,
    };
  }
}