import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuration pour Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMgD-kNJNirPQl6jWz9lsBBUvelzQ8n5E',
    authDomain: 'chatapp-light1.firebaseapp.com',
    projectId: 'chatapp-light1',
    storageBucket: 'chatapp-light1.firebasestorage.app',
    messagingSenderId: '695148690786',
    appId: '1:695148690786:web:b4d2e98e4a6116a659c03b',
  );

  // Configuration pour Android (même valeurs pour l'instant)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMgD-kNJNirPQl6jWz9lsBBUvelzQ8n5E',
    appId: '1:695148690786:web:b4d2e98e4a6116a659c03b',
    messagingSenderId: '695148690786',
    projectId: 'chatapp-light1',
    storageBucket: 'chatapp-light1.firebasestorage.app',
  );

  // Configuration pour iOS (même valeurs pour l'instant)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDMgD-kNJNirPQl6jWz9lsBBUvelzQ8n5E',
    appId: '1:695148690786:web:b4d2e98e4a6116a659c03b',
    messagingSenderId: '695148690786',
    projectId: 'chatapp-light1',
    storageBucket: 'chatapp-light1.firebasestorage.app',
    iosBundleId: 'com.example.chatappLight',
  );
}