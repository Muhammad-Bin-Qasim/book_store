import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen(
      (appUser) {
        _currentUser = appUser;
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (Object error) {
        _currentUser = null;
        _errorMessage = ErrorHandler.message(
          error,
          fallback: AppStrings.authGenericError,
        );
        _disabledAccountNotice =
            error is AuthServiceException && error.isDisabled;
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      },
    );
  }

  final AuthService _authService;
  late final StreamSubscription<AppUser?> _authSubscription;
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _disabledAccountNotice = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isLoading => _isLoading;
  bool get isInitializing => !_isInitialized;
  String? get errorMessage => _errorMessage;
  bool get showDisabledAccountNotice => _disabledAccountNotice;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _perform(() async {
      _currentUser = await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<bool> login({required String email, required String password}) {
    return _perform(() async {
      _currentUser = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
    });
  }

  Future<bool> googleLogin() {
    return _perform(() async {
      _currentUser = await _authService.signInWithGoogle();
    });
  }

  Future<bool> updateDisplayName(String name) {
    return _perform(() async {
      _currentUser = await _authService.updateDisplayName(name);
    });
  }

  Future<bool> resetPassword({required String email}) {
    return _perform(() => _authService.sendPasswordReset(email: email));
  }

  Future<bool> logout() {
    return _perform(() async {
      await _authService.logout();
      _currentUser = null;
    });
  }

  Future<bool> _perform(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _disabledAccountNotice = false;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = ErrorHandler.message(
        error,
        fallback: AppStrings.authGenericError,
      );
      _disabledAccountNotice =
          error is AuthServiceException && error.isDisabled;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _disabledAccountNotice = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
