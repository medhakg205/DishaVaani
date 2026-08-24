// Generated-style Firebase options for the DishaVaani Firebase project.
// Re-run `flutterfire configure` if Firebase apps or credentials change.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options have not been configured for Linux.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options have not been configured for Fuchsia.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCeuoPg22khnJAKo0tI5VaHbXCAKjx1r1Y',
    appId: '1:430937452151:web:c745565e5bc1337c4e6072',
    messagingSenderId: '430937452151',
    projectId: 'dishavaani-db373',
    storageBucket: 'dishavaani-db373.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeuoPg22khnJAKo0tI5VaHbXCAKjx1r1Y',
    appId: '1:430937452151:android:d074954f18a01f174e6072',
    messagingSenderId: '430937452151',
    projectId: 'dishavaani-db373',
    storageBucket: 'dishavaani-db373.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCeuoPg22khnJAKo0tI5VaHbXCAKjx1r1Y',
    appId: '1:430937452151:ios:5cc630ea6d15a1dd4e6072',
    messagingSenderId: '430937452151',
    projectId: 'dishavaani-db373',
    storageBucket: 'dishavaani-db373.firebasestorage.app',
    iosBundleId: 'com.example.dishaVaani',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCeuoPg22khnJAKo0tI5VaHbXCAKjx1r1Y',
    appId: '1:430937452151:ios:5cc630ea6d15a1dd4e6072',
    messagingSenderId: '430937452151',
    projectId: 'dishavaani-db373',
    storageBucket: 'dishavaani-db373.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCeuoPg22khnJAKo0tI5VaHbXCAKjx1r1Y',
    appId: '1:430937452151:web:37672a70d9eb3c664e6072',
    messagingSenderId: '430937452151',
    projectId: 'dishavaani-db373',
    storageBucket: 'dishavaani-db373.firebasestorage.app',
  );
}
