import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        // Windows: dùng cùng project; cần thêm Web app trên Firebase Console
        // và điền apiKey/appId web vào đây nếu build Windows chat.
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClXF69MEyx-uSutlQHuNeVK6ENSyvJg_8',
    appId: '1:886555523620:android:1c232303911c1f6bd576b1',
    messagingSenderId: '886555523620',
    projectId: 'kinh-7713d',
    databaseURL:
        'https://kinh-7713d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'kinh-7713d.appspot.com',
  );

  /// Thêm app **Web** trong Firebase → dán apiKey + appId vào đây.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyClXF69MEyx-uSutlQHuNeVK6ENSyvJg_8',
    appId: '1:886555523620:android:1c232303911c1f6bd576b1',
    messagingSenderId: '886555523620',
    projectId: 'kinh-7713d',
    databaseURL:
        'https://kinh-7713d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'kinh-7713d.appspot.com',
    authDomain: 'kinh-7713d.firebaseapp.com',
  );

  static const FirebaseOptions web = windows;
}
