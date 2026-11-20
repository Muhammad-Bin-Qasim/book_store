import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../app_constants.dart';

abstract interface class UserFacingError {
  String get userMessage;
}

class ErrorHandler {
  ErrorHandler._();

  static String message(Object error, {String? fallback}) {
    if (error is UserFacingError) return error.userMessage;
    if (error is TimeoutException || _looksLikeNetworkFailure(error)) {
      return AppStrings.noInternetConnection;
    }

    if (error is FirebaseAuthException) {
      return _authMessage(error.code);
    }
    if (error is FirebaseException) {
      return _firebaseMessage(error.code);
    }
    if (error is PlatformException) {
      return _platformMessage(error.code);
    }
    return fallback ?? AppStrings.genericError;
  }

  static String _authMessage(String code) {
    final normalizedCode = _normalizeCode(code);
    return switch (normalizedCode) {
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' => AppStrings.authInvalidCredentials,
      'user-not-found' => AppStrings.authUserNotFound,
      'email-already-in-use' => AppStrings.authEmailInUse,
      'weak-password' => AppStrings.authWeakPassword,
      'invalid-email' => AppStrings.authInvalidEmail,
      'user-disabled' => AppStrings.authUserDisabled,
      'too-many-requests' => AppStrings.authTooManyRequests,
      'network-request-failed' => AppStrings.noInternetConnection,
      'operation-not-allowed' => AppStrings.authProviderDisabled,
      'popup-closed-by-user' ||
      'cancelled-popup-request' => AppStrings.authPopupClosed,
      'popup-blocked' || 'unauthorized-domain' => AppStrings.authPopupBlocked,
      'account-exists-with-different-credential' ||
      'credential-already-in-use' => AppStrings.authAccountConflict,
      _ => AppStrings.authGenericError,
    };
  }

  static String _firebaseMessage(String code) {
    final normalizedCode = _normalizeCode(code);
    return switch (normalizedCode) {
      'permission-denied' ||
      'unauthenticated' => AppStrings.permissionDeniedError,
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppStrings.noInternetConnection,
      'not-found' => AppStrings.notFoundError,
      _ => AppStrings.genericError,
    };
  }

  static String _platformMessage(String code) {
    final normalizedCode = _normalizeCode(code);
    return switch (normalizedCode) {
      'sign_in_canceled' ||
      'sign_in_cancelled' => AppStrings.authGoogleCancelled,
      'network_error' => AppStrings.noInternetConnection,
      _ => AppStrings.genericError,
    };
  }

  static String _normalizeCode(String code) {
    final separator = code.lastIndexOf('/');
    return (separator < 0 ? code : code.substring(separator + 1))
        .trim()
        .toLowerCase();
  }

  static bool _looksLikeNetworkFailure(Object error) {
    final description = error.toString().toLowerCase();
    return description.contains('socketexception') ||
        description.contains('failed host lookup') ||
        description.contains('network is unreachable') ||
        description.contains('connection timed out') ||
        description.contains('connection refused') ||
        description.contains('no address associated with hostname') ||
        description.contains('network request failed') ||
        description.contains('internet connection');
  }
}
