import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/book.dart';
import '../services/wishlist_service.dart';
import 'book_provider.dart';

class WishlistProvider extends ChangeNotifier {
  WishlistProvider({WishlistService? wishlistService})
    : _wishlistService = wishlistService ?? WishlistService();

  final WishlistService _wishlistService;
  BookProvider? _bookProvider;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Set<String> _bookIds = <String>{};
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get bookIds => Set<String>.unmodifiable(_bookIds);
  List<Book> get books => (_bookProvider?.allBooks ?? const <Book>[])
      .where((book) => _bookIds.contains(book.id))
      .toList(growable: false);

  bool isInWishlist(String bookId) => _bookIds.contains(bookId);

  void bind(String? userId, BookProvider bookProvider) {
    final booksChanged = !identical(_bookProvider, bookProvider);
    _bookProvider = bookProvider;
    if (_userId == userId) {
      if (booksChanged) notifyListeners();
      return;
    }
    _userId = userId;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _bookIds.clear();
    _errorMessage = null;
    _isLoading = userId != null;
    notifyListeners();
    if (userId == null) return;
    _startListening(userId);
  }

  void retry() {
    final userId = _userId;
    if (userId == null) return;
    unawaited(_subscription?.cancel());
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _startListening(userId);
  }

  void _startListening(String userId) {
    _subscription = _wishlistService
        .watchWishlist(userId)
        .listen(
          (snapshot) {
            if (_userId != userId) return;
            _bookIds
              ..clear()
              ..addAll(snapshot.docs.map((document) => document.id));
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (_userId != userId) return;
            _isLoading = false;
            _errorMessage = ErrorHandler.message(
              error,
              fallback: AppStrings.wishlistOperationFailed,
            );
            notifyListeners();
          },
        );
  }

  Future<void> addToWishlist(String bookId) async {
    if (isInWishlist(bookId)) return;
    final uid = _requireUser();
    _bookIds.add(bookId);
    notifyListeners();
    try {
      await _wishlistService.addToWishlist(uid, bookId);
    } catch (error) {
      _bookIds.remove(bookId);
      notifyListeners();
      throw WishlistOperationException(
        ErrorHandler.message(
          error,
          fallback: AppStrings.wishlistOperationFailed,
        ),
      );
    }
  }

  Future<void> removeFromWishlist(String bookId) async {
    if (!isInWishlist(bookId)) return;
    final uid = _requireUser();
    _bookIds.remove(bookId);
    notifyListeners();
    try {
      await _wishlistService.removeFromWishlist(uid, bookId);
    } catch (error) {
      _bookIds.add(bookId);
      notifyListeners();
      throw WishlistOperationException(
        ErrorHandler.message(
          error,
          fallback: AppStrings.wishlistOperationFailed,
        ),
      );
    }
  }

  Future<void> toggleWishlist(String bookId) =>
      isInWishlist(bookId) ? removeFromWishlist(bookId) : addToWishlist(bookId);

  String _requireUser() {
    final uid = _userId;
    if (uid == null) {
      throw const WishlistOperationException(
        AppStrings.loginRequiredForWishlist,
      );
    }
    return uid;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class WishlistOperationException implements Exception, UserFacingError {
  const WishlistOperationException(this.message);
  final String message;
  @override
  String get userMessage => message;

  @override
  String toString() => message;
}
