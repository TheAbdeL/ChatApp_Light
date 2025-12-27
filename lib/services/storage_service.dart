import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion du stockage Firebase
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ==================== UPLOAD D'IMAGES ====================

  /// Upload une image de profil utilisateur (WEB + MOBILE)
  Future<String?> uploadProfileImage({
    required String userId,
    required dynamic imageFile,
  }) async {
    try {
      debugPrint('📤 Upload de l\'image de profil pour $userId...');
      
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profile_images').child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask;
      
      if (kIsWeb) {
        final bytes = await (imageFile as XFile).readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        uploadTask = ref.putFile(imageFile as File, metadata);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image de profil uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload image de profil: $e');
      return null;
    }
  }

  /// Upload une image de chat avec progression (WEB + MOBILE)
  Future<String?> uploadChatImage({
    required String senderId,
    required String receiverId,
    required dynamic imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final String chatId = '${senderId}_$receiverId';
      debugPrint('📤 Upload de l\'image pour le chat $chatId...');

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('chat_images')
          .child(chatId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'chatId': chatId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask;
      
      if (kIsWeb) {
        final bytes = await (imageFile as XFile).readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        uploadTask = ref.putFile(imageFile as File, metadata);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('📊 Progression: ${(progress * 100).toStringAsFixed(0)}%');
        onProgress?.call(progress);
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image de chat uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload image de chat: $e');
      return null;
    }
  }

  /// Upload une image pour un groupe ou chat
  Future<String?> uploadGroupImage({
    required String chatId,
    required dynamic imageFile,
  }) async {
    try {
      debugPrint('📤 Upload de l\'image pour le chat/groupe $chatId...');

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('chat_images')
          .child(chatId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'chatId': chatId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask;
      
      if (kIsWeb) {
        final bytes = await (imageFile as XFile).readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        uploadTask = ref.putFile(imageFile as File, metadata);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image de chat/groupe uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload image: $e');
      return null;
    }
  }

  /// Upload message vocal pour chat ou groupe
  Future<String?> uploadVoiceMessage({
    required String chatId,
    required String audioPath,
  }) async {
    try {
      debugPrint('🎤 Upload message vocal pour $chatId...');

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
      final Reference ref = _storage
          .ref()
          .child('voice_messages')
          .child(chatId)
          .child(fileName);

      final File audioFile = File(audioPath);
      final UploadTask uploadTask = ref.putFile(audioFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Message vocal uploadé: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Erreur upload vocal: $e');
      return null;
    }
  }

  // ==================== SÉLECTION D'IMAGES ====================

  /// Sélectionner une image depuis la galerie (WEB + MOBILE)
  Future<dynamic> pickImageFromGallery({
    int imageQuality = 70,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      debugPrint('🖼️ Ouverture de la galerie...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
      );

      if (image != null) {
        debugPrint('✅ Image sélectionnée: ${image.path}');
        if (kIsWeb) {
          return image;
        } else {
          return File(image.path);
        }
      } else {
        debugPrint('⚠️ Aucune image sélectionnée');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection galerie: $e');
      return null;
    }
  }

  /// Sélectionner une image depuis la caméra (MOBILE UNIQUEMENT)
  Future<File?> pickImageFromCamera({
    int imageQuality = 70,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      if (kIsWeb) {
        debugPrint('⚠️ Caméra non disponible sur Web');
        return null;
      }

      debugPrint('📸 Ouverture de la caméra...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
      );

      if (image != null) {
        debugPrint('✅ Photo prise: ${image.path}');
        return File(image.path);
      } else {
        debugPrint('⚠️ Aucune photo prise');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur prise de photo: $e');
      return null;
    }
  }

  // ==================== SUPPRESSION ====================

  /// Supprimer une image par son URL
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      debugPrint('🗑️ Suppression de l\'image...');
      
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      debugPrint('✅ Image supprimée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression image: $e');
      return false;
    }
  }

  /// Supprimer une image de profil
  Future<bool> deleteProfileImage(String userId) async {
    try {
      debugPrint('🗑️ Suppression image de profil pour $userId...');
      
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profile_images').child(fileName);
      await ref.delete();
      
      debugPrint('✅ Image de profil supprimée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression image de profil: $e');
      return false;
    }
  }

  // ==================== UTILITAIRES ====================

  /// Obtenir la taille d'un fichier
  Future<int?> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      debugPrint('❌ Erreur lecture taille fichier: $e');
      return null;
    }
  }

  /// Vérifier si un fichier est trop volumineux (max 5MB par défaut)
  Future<bool> isFileTooLarge(File file, {int maxSizeMB = 5}) async {
    final int? size = await getFileSize(file);
    if (size == null) return true;
    
    final int maxSizeBytes = maxSizeMB * 1024 * 1024;
    return size > maxSizeBytes;
  }

  /// Obtenir le format lisible de la taille d'un fichier
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}