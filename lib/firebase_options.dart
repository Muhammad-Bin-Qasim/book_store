// Firebase platform IDs match firebase.json and android/app/google-services.json.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => android,
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCu8kKX0FlISttgphf-k7vTdLKg19ewxe0',
    appId: '1:79261832568:web:a3ac81c9e5c2dd9759648d',
    messagingSenderId: '79261832568',
    projectId: 'book-store-a5525',
    authDomain: 'book-store-a5525.firebaseapp.com',
    storageBucket: 'book-store-a5525.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCu8kKX0FlISttgphf-k7vTdLKg19ewxe0',
    appId: '1:79261832568:android:d48a1221a98c76cb59648d',
    messagingSenderId: '79261832568',
    projectId: 'book-store-a5525',
    storageBucket: 'book-store-a5525.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCu8kKX0FlISttgphf-k7vTdLKg19ewxe0',
    appId: '1:79261832568:ios:replace-with-ios-app-id',
    messagingSenderId: '79261832568',
    projectId: 'book-store-a5525',
    storageBucket: 'book-store-a5525.firebasestorage.app',
    iosBundleId: 'com.example.bookStore',
  );
}
