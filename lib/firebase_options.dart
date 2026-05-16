import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCgN3fhqrdbv05x4XR5rozJhAjZ6AMDLSs',
    appId: '1:131072767171:web:382c34039d8d88b4de9e76',
    messagingSenderId: '131072767171',
    projectId: 'catequesis-9a5ad',
    authDomain: 'catequesis-9a5ad.firebaseapp.com',
    storageBucket: 'catequesis-9a5ad.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA681XZzwF3fBNdyi-Zsz3-DS9tpGxGzYQ',
    appId: '1:131072767171:android:846bfa41aee6f06bde9e76',
    messagingSenderId: '131072767171',
    projectId: 'catequesis-9a5ad',
    storageBucket: 'catequesis-9a5ad.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCe3Ea_AOC7FNJCAhgh0ZXrwzud_QjDsC0',
    appId: '1:131072767171:ios:65feb7e968a3541ede9e76',
    messagingSenderId: '131072767171',
    projectId: 'catequesis-9a5ad',
    storageBucket: 'catequesis-9a5ad.firebasestorage.app',
    iosBundleId: 'com.example.catequesis',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCe3Ea_AOC7FNJCAhgh0ZXrwzud_QjDsC0',
    appId: '1:131072767171:ios:65feb7e968a3541ede9e76',
    messagingSenderId: '131072767171',
    projectId: 'catequesis-9a5ad',
    storageBucket: 'catequesis-9a5ad.firebasestorage.app',
    iosBundleId: 'com.example.catequesis',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgN3fhqrdbv05x4XR5rozJhAjZ6AMDLSs',
    appId: '1:131072767171:web:b4b2e145d5ee702ade9e76',
    messagingSenderId: '131072767171',
    projectId: 'catequesis-9a5ad',
    authDomain: 'catequesis-9a5ad.firebaseapp.com',
    storageBucket: 'catequesis-9a5ad.firebasestorage.app',
  );
}
