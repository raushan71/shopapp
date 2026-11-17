// Firebase options synchronized from the native Android and iOS config files.
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBiUPOUTOFt2fc_6YT63_ft7bUvEPe1Kl8',
    appId: '1:125070104915:android:fd6adac4cf1d700bbbe9a6',
    messagingSenderId: '125070104915',
    projectId: 'shop-f9ed5',
    storageBucket: 'shop-f9ed5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjPRnp4avrrFwBF-w2hzXP0XJM8wyqNeU',
    appId: '1:125070104915:ios:d794c65817b463ddbbe9a6',
    messagingSenderId: '125070104915',
    projectId: 'shop-f9ed5',
    storageBucket: 'shop-f9ed5.firebasestorage.app',
    iosClientId: '125070104915-pcdu597vcnrianckocgln2oocg151esc.apps.googleusercontent.com',
    iosBundleId: 'com.itrsp.shop',
  );

}