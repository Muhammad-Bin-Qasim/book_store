import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/app_user.dart';

class AuthServiceException implements Exception, UserFacingError {
  const AuthServiceException(this.message, {this.isDisabled = false});

  final String message;
  final bool isDisabled;

  @override
  String get userMessage => message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().asyncMap(
    (firebaseUser) async =>
        firebaseUser == null ? null : _ensureUserDocument(firebaseUser),
  );

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) {
    return _translateErrors(() async {
      final normalizedName = name.trim();
      final normalizedEmail = email.trim();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthServiceException(AppStrings.authGenericError);
      }
      await firebaseUser.updateDisplayName(normalizedName);
      final userData = <String, dynamic>{
        'name': normalizedName,
        'email': firebaseUser.email ?? normalizedEmail,
        'role': UserRole.user.name,
        'disabled': false,
        'addresses': <Map<String, dynamic>>[],
        'paymentMethods': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _users.doc(firebaseUser.uid).set(userData);
      return AppUser.fromMap(userData, uid: firebaseUser.uid);
    });
  }

  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _translateErrors(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthServiceException(AppStrings.authGenericError);
      }
      return _ensureUserDocument(firebaseUser);
    });
  }

  Future<AppUser> signInWithGoogle() {
    return _translateErrors(() async {
      late final UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleAccount = await _googleSignIn.signIn();
        if (googleAccount == null) {
          throw const AuthServiceException(AppStrings.authGoogleCancelled);
        }
        final googleAuthentication = await googleAccount.authentication;
        final googleCredential = GoogleAuthProvider.credential(
          accessToken: googleAuthentication.accessToken,
          idToken: googleAuthentication.idToken,
        );
        credential = await _auth.signInWithCredential(googleCredential);
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthServiceException(AppStrings.authGenericError);
      }
      return _ensureUserDocument(firebaseUser);
    });
  }

  Future<AppUser> updateDisplayName(String name) async {
    return _translateErrors(() async {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw const AuthServiceException(AppStrings.authGenericError);
      }
      final normalizedName = name.trim();
      await firebaseUser.updateDisplayName(normalizedName);
      await _users.doc(firebaseUser.uid).set(<String, dynamic>{
        'name': normalizedName,
      }, SetOptions(merge: true));
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        throw const AuthServiceException(AppStrings.authGenericError);
      }
      return _ensureUserDocument(refreshedUser);
    });
  }

  Future<void> sendPasswordReset({required String email}) {
    return _translateErrors(() async {
      await _auth.sendPasswordResetEmail(email: email.trim());
    });
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } on Exception {
        // Firebase sign-out still needs to complete if the Google session is stale.
      }
    }
    await _translateErrors(_auth.signOut);
  }

  Future<AppUser?> getCurrentAppUser() {
    return _translateErrors(() async {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      return _ensureUserDocument(firebaseUser);
    });
  }

  Future<AppUser> _ensureUserDocument(User firebaseUser) async {
    final reference = _users.doc(firebaseUser.uid);
    try {
      return await _firestore.runTransaction<AppUser>((transaction) async {
        final snapshot = await transaction.get(reference);
        final existingData = snapshot.data();
        if (snapshot.exists && existingData != null) {
          if (existingData['disabled'] == true) {
            throw const AuthServiceException(
              AppStrings.adminAccountDisabledNotice,
              isDisabled: true,
            );
          }
          return AppUser.fromMap(existingData, uid: firebaseUser.uid);
        }

        final userData = <String, dynamic>{
          'name': firebaseUser.displayName ?? '',
          'email': firebaseUser.email ?? '',
          'role': UserRole.user.name,
          'disabled': false,
          'addresses': <Map<String, dynamic>>[],
          'paymentMethods': <Map<String, dynamic>>[],
          'createdAt': FieldValue.serverTimestamp(),
        };
        transaction.set(reference, userData);
        return AppUser.fromMap(userData, uid: firebaseUser.uid);
      });
    } on AuthServiceException catch (error) {
      if (error.isDisabled) await _auth.signOut();
      rethrow;
    }
  }

  Future<T> _translateErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthServiceException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(ErrorHandler.message(error));
    } on FirebaseException catch (error) {
      throw AuthServiceException(ErrorHandler.message(error));
    } on PlatformException catch (error) {
      throw AuthServiceException(ErrorHandler.message(error));
    } catch (error) {
      throw AuthServiceException(
        ErrorHandler.message(error, fallback: AppStrings.authGenericError),
      );
    }
  }

  static String friendlyMessage(Object error) {
    return ErrorHandler.message(error, fallback: AppStrings.authGenericError);
  }
}
