// Điền từ Firebase Console → Project settings → Your apps
// hoặc `flutterfire configure`
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
        return windows;
      default:
        return android;
    }
  }

  // TODO: thay bằng giá trị project Firebase của bạn
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClXF69MEyx-uSutlQHuNeVK6ENSyvJg_8',
    appId: '1:886555523620:android:1c232303911c1f6bd576b1',
    messagingSenderId: '886555523620',
    projectId: 'kinh-7713d',
    databaseURL: 'https://kinh-7713d-default-rtdb.asia-southeast1.firebasedatabase.app/',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WEB_API_KEY',
    appId: 'REPLACE_WEB_APP_ID',
    messagingSenderId: 'REPLACE_SENDER_ID',
    projectId: 'REPLACE_PROJECT_ID',
    databaseURL: 'https://REPLACE_PROJECT_ID-default-rtdb.firebaseio.com',
    storageBucket: 'REPLACE_PROJECT_ID.appspot.com',
    authDomain: 'REPLACE_PROJECT_ID.firebaseapp.com',
  );

  static const FirebaseOptions web = windows;
}
