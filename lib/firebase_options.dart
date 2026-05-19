import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured for this project.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows is not configured for this project.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not configured for this project.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDixJkieP5qJdSZB0LXdK0plqPYywDXpQ',
    appId: '1:923195818513:android:56490f43a9e25b7fd567b0',
    messagingSenderId: '923195818513',
    projectId: 'speechyai-5bf0b',
    storageBucket: 'speechyai-5bf0b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7JIdelxsCZR0uX5A2iZ13x-8v8YPXQhA',
    appId: '1:923195818513:ios:dd9b5fa8d058c71bd567b0',
    messagingSenderId: '923195818513',
    projectId: 'speechyai-5bf0b',
    storageBucket: 'speechyai-5bf0b.firebasestorage.app',
    androidClientId: '923195818513-5hbldmprlfeb9l22hqe9q4vcbaue8ru1.apps.googleusercontent.com',
    iosClientId: '923195818513-ic0oatv3e43qsee0l8fhhlhhhat97nas.apps.googleusercontent.com',
    iosBundleId: 'com.furqat.speechyai',
  );

}