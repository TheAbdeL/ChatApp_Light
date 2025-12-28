import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service audio simple pour étudiants
class AudioServiceSimple {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  /// Initialiser le recorder
  Future<void> initRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isRecorderInitialized = true;
      debugPrint('✅ Recorder initialisé');
    } catch (e) {
      debugPrint('❌ Erreur init recorder: $e');
    }
  }

  /// Initialiser le player
  Future<void> initPlayer() async {
    try {
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      _isPlayerInitialized = true;
      debugPrint('✅ Player initialisé');
    } catch (e) {
      debugPrint('❌ Erreur init player: $e');
    }
  }

  /// Demander la permission microphone
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('❌ Erreur permission: $e');
      return false;
    }
  }

  /// Démarrer l'enregistrement
  Future<bool> startRecording() async {
    try {
      // Vérifier permission
      if (!await requestPermission()) {
        debugPrint('❌ Permission refusée');
        return false;
      }

      // Initialiser si nécessaire
      if (!_isRecorderInitialized) {
        await initRecorder();
      }

      // Créer le chemin
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.aac';

      // Démarrer
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _isRecording = true;
      debugPrint('✅ Enregistrement démarré: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur start recording: $e');
      return false;
    }
  }

  /// Arrêter l'enregistrement
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint('⚠️ Pas d\'enregistrement en cours');
        return null;
      }

      await _recorder!.stopRecorder();
      _isRecording = false;

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('✅ Enregistrement arrêté: ${(size / 1024).toStringAsFixed(2)} KB');
          
          if (size > 1000) {
            return _currentRecordingPath;
          } else {
            debugPrint('⚠️ Fichier trop petit');
            await file.delete();
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Annuler l'enregistrement
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder!.stopRecorder();
        _isRecording = false;
        
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Enregistrement supprimé');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur cancel: $e');
    }
  }

  /// Jouer un audio depuis URL
  Future<void> playAudio(String url) async {
    try {
      if (!_isPlayerInitialized) {
        await initPlayer();
      }

      await _player!.startPlayer(
        fromURI: url,
        codec: Codec.aacADTS,
      );
      debugPrint('▶️ Lecture: $url');
    } catch (e) {
      debugPrint('❌ Erreur play: $e');
    }
  }

  /// Arrêter la lecture
  Future<void> stopAudio() async {
    try {
      if (_isPlayerInitialized) {
        await _player!.stopPlayer();
        debugPrint('⏹️ Lecture arrêtée');
      }
    } catch (e) {
      debugPrint('❌ Erreur stop play: $e');
    }
  }

  /// Vérifier si en cours de lecture
  bool get isPlaying => _player?.isPlaying ?? false;

  /// Stream de la position
  Stream<Duration>? get onProgress => _player?.onProgress?.map((e) => e.position);

  /// Nettoyer
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder!.stopRecorder();
      }
      await _recorder?.closeRecorder();
      await _player?.closePlayer();
      _recorder = null;
      _player = null;
      debugPrint('✅ Audio service disposed');
    } catch (e) {
      debugPrint('❌ Erreur dispose: $e');
    }
  }

  /// Formater la durée
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}