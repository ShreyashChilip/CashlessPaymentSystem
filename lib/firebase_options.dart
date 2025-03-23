// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    if (kIsWeb) {
      return web;
    }
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC9ZZDD79jhGYnJj4YaMXtkNfEMSogq-OY',
    appId: '1:24195492669:web:4b60f00ed2281c786ff354',
    messagingSenderId: '24195492669',
    projectId: 'bhai-94b77',
    authDomain: 'bhai-94b77.firebaseapp.com',
    storageBucket: 'bhai-94b77.firebasestorage.app',
    measurementId: 'G-1ZSB8YJP3C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfRA8oVVkiu-0f2FhXlgUrJVkcHJ0YI40',
    appId: '1:24195492669:android:a28669f17d1aa4b86ff354',
    messagingSenderId: '24195492669',
    projectId: 'bhai-94b77',
    storageBucket: 'bhai-94b77.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwmUWSUuhwv8Fto5H_yjweNm-8P48eANU',
    appId: '1:24195492669:ios:5db4456093b6f00b6ff354',
    messagingSenderId: '24195492669',
    projectId: 'bhai-94b77',
    storageBucket: 'bhai-94b77.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDwmUWSUuhwv8Fto5H_yjweNm-8P48eANU',
    appId: '1:24195492669:ios:5db4456093b6f00b6ff354',
    messagingSenderId: '24195492669',
    projectId: 'bhai-94b77',
    storageBucket: 'bhai-94b77.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC9ZZDD79jhGYnJj4YaMXtkNfEMSogq-OY',
    appId: '1:24195492669:web:ce5bd9b14ee4fd156ff354',
    messagingSenderId: '24195492669',
    projectId: 'bhai-94b77',
    authDomain: 'bhai-94b77.firebaseapp.com',
    storageBucket: 'bhai-94b77.firebasestorage.app',
    measurementId: 'G-50QRJ5TE9X',
  );
}
