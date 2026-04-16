import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TODO: Replace with your actual Firebase Options by running `flutterfire configure`
    return const FirebaseOptions(
      apiKey: 'REPLACE_ME_API_KEY',
      appId: 'REPLACE_ME_APP_ID',
      messagingSenderId: 'REPLACE_ME_SENDER_ID',
      projectId: 'genesis-hub-placeholder',
    );
  }
}
