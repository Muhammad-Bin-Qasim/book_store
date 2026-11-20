import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/book.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import 'book_provider.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({CartService? cartService})
    : _cartService = cartService ?? CartService();

  final CartService _cartService;
  BookProvider? _bookProvider;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _userId;
  final Map<String, int> _quantities = <String, int>{};
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount =>
      _quantities.values.fold<int>(0, (total, quantity) => total + quantity);

  List<CartItem> get items {
    final booksById = <String, Book>{
      for (final book in _bookProvider?.allBooks ?? const <Book>[])
        book.id: book,
    };
    return _quantities.entries
        .map((entry) {
          final book = booksById[entry.key];
          return CartItem(
            id: entry.key,
            bookId: entry.key,
            title: book?.title ?? AppStrings.unavailableBook,
            author: book?.author ?? '',
            coverUrl: book?.coverUrl ?? '',
            price: book?.price ?? 0,
            quantity: entry.value,
            unavailable: book == null,
          );
        })
        .toList(growable: false);
  }

  double get subtotal => items.fold<double>(
    0,
    (subtotal, item) =>
        subtotal + (item.unavailable ? 0 : item.price * item.quantity),
  );
  double get total => subtotal;
  bool contains(String bookId) => _quantities.containsKey(bookId);
  int quantityFor(String bookId) => _quantities[bookId] ?? 0;

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
    _quantities.clear();
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
    _subscription = _cartService
        .watchCart(userId)
        .listen(
          (snapshot) {
            if (_userId != userId) return;
            _quantities
              ..clear()
              ..addEntries(
                snapshot.docs.map((document) {
                  final value = document.data()['quantity'];
                  final quantity = value is num ? value.toInt() : 1;
                  return MapEntry(document.id, quantity.clamp(1, 10).toInt());
                }),
              );
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (_userId != userId) return;
            _isLoading = false;
            _errorMessage = ErrorHandler.message(
              error,
              fallback: AppStrings.cartOperationFailed,
            );
            notifyListeners();
          },
        );
  }

  Future<void> addToCart(Book book, {int quantity = 1}) async {
    final uid = _requireUser();
    final increment = quantity.clamp(1, 10).toInt();
    final previous = _quantities[book.id];
    _quantities[book.id] = ((previous ?? 0) + increment).clamp(1, 10).toInt();
    notifyListeners();
    try {
      await _cartService.addToCart(uid, book, quantity: increment);
    } catch (error) {
      _restore(book.id, previous);
      throw CartOperationException(
        ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
      );
    }
  }

  Future<void> updateQuantity(String bookId, int quantity) async {
    if (quantity < 1 || quantity > 10) return;
    final uid = _requireUser();
    final previous = _quantities[bookId];
    if (previous == null) return;
    _quantities[bookId] = quantity;
    notifyListeners();
    try {
      await _cartService.updateQuantity(uid, bookId, quantity);
    } catch (error) {
      _restore(bookId, previous);
      throw CartOperationException(
        ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
      );
    }
  }

  Future<void> removeItem(String bookId) async {
    final uid = _requireUser();
    final previous = _quantities.remove(bookId);
    if (previous == null) return;
    notifyListeners();
    try {
      await _cartService.removeItem(uid, bookId);
    } catch (error) {
      _restore(bookId, previous);
      throw CartOperationException(
        ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
      );
    }
  }

  Future<void> restoreItem(String bookId, int quantity) async {
    final uid = _requireUser();
    final previous = _quantities[bookId];
    _quantities[bookId] = quantity.clamp(1, 10).toInt();
    notifyListeners();
    try {
      await _cartService.restoreItem(uid, bookId, quantity);
    } catch (error) {
      _restore(bookId, previous);
      throw CartOperationException(
        ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
      );
    }
  }

  Future<void> clearCart() async {
    final uid = _requireUser();
    final previous = Map<String, int>.from(_quantities);
    _quantities.clear();
    notifyListeners();
    try {
      await _cartService.clearCart(uid);
    } catch (error) {
      _quantities
        ..clear()
        ..addAll(previous);
      notifyListeners();
      throw CartOperationException(
        ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
      );
    }
  }

  String _requireUser() {
    final uid = _userId;
    if (uid == null) {
      throw const CartOperationException(AppStrings.loginRequiredForCart);
    }
    return uid;
  }

  void _restore(String id, int? previous) {
    if (previous == null) {
      _quantities.remove(id);
    } else {
      _quantities[id] = previous;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class CartOperationException implements Exception, UserFacingError {
  const CartOperationException(this.message);
  final String message;
  @override
  String get userMessage => message;

  @override
  String toString() => message;
}
