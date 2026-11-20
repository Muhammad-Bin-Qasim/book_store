import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/app_user.dart';
import '../models/book.dart';
import '../models/order.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;
  String? _boundUserId;
  bool _boundAsAdmin = false;
  bool _usersLoaded = false;
  bool _ordersLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<AppUser> _users = const <AppUser>[];
  List<Order> _orders = const <Order>[];

  List<AppUser> get users => List<AppUser>.unmodifiable(_users);
  List<Order> get orders => List<Order>.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _usersLoaded && _ordersLoaded;

  AppUser? userById(String uid) {
    for (final user in _users) {
      if (user.uid == uid) return user;
    }
    return null;
  }

  void bind({required String? userId, required bool isAdmin}) {
    if (_boundUserId == userId && _boundAsAdmin == isAdmin) return;
    _boundUserId = userId;
    _boundAsAdmin = isAdmin;
    unawaited(_usersSubscription?.cancel());
    unawaited(_ordersSubscription?.cancel());
    _usersSubscription = null;
    _ordersSubscription = null;
    _usersLoaded = false;
    _ordersLoaded = false;
    _users = const <AppUser>[];
    _orders = const <Order>[];
    _errorMessage = null;
    _isLoading = isAdmin;
    notifyListeners();
    if (!isAdmin) return;
    _usersSubscription = _firestore.collection('users').snapshots().listen((
      snapshot,
    ) {
      if (!_boundAsAdmin || _boundUserId != userId) return;
      _users =
          snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), uid: doc.id))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      _usersLoaded = true;
      _updateLoading();
    }, onError: _handleError);
    _ordersSubscription = _firestore.collection('orders').snapshots().listen((
      snapshot,
    ) {
      if (!_boundAsAdmin || _boundUserId != userId) return;
      _orders =
          snapshot.docs
              .map((doc) => Order.fromMap(doc.data(), id: doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _ordersLoaded = true;
      _updateLoading();
    }, onError: _handleError);
  }

  void _updateLoading() {
    _isLoading = !(_usersLoaded && _ordersLoaded);
    if (hasLoaded) _errorMessage = null;
    notifyListeners();
  }

  void _handleError(Object error) {
    _isLoading = false;
    _errorMessage = _friendlyError(error);
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_boundAsAdmin) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        _firestore.collection('users').get(),
        _firestore.collection('orders').get(),
      ]);
      if (!_boundAsAdmin) return;
      _users =
          results[0].docs
              .map((doc) => AppUser.fromMap(doc.data(), uid: doc.id))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      _orders =
          results[1].docs
              .map((doc) => Order.fromMap(doc.data(), id: doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _usersLoaded = true;
      _ordersLoaded = true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      throw AdminOperationException(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String createBookId() => _firestore.collection('books').doc().id;

  Future<void> createBook(Book book) async {
    try {
      await _firestore.collection('books').doc(book.id).set(book.toMap());
    } catch (error) {
      throw AdminOperationException(_friendlyError(error));
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      final values =
          book.toMap()
            ..remove('avgRating')
            ..remove('ratingCount');
      await _firestore.collection('books').doc(book.id).update(values);
    } catch (error) {
      throw AdminOperationException(_friendlyError(error));
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
    } catch (error) {
      throw AdminOperationException(_friendlyError(error));
    }
  }

  Future<String> uploadCover({
    required String bookId,
    required Uint8List bytes,
    required String contentType,
    required ValueChanged<double> onProgress,
  }) async {
    try {
      final reference = _storage.ref('books/$bookId/cover.jpg');
      final task = reference.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final subscription = task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
      try {
        await task;
      } finally {
        await subscription.cancel();
      }
      return await reference.getDownloadURL();
    } catch (error) {
      throw AdminOperationException(AppStrings.storageUploadFailed);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus nextStatus) async {
    final reference = _firestore.collection('orders').doc(orderId);
    try {
      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          throw const AdminOperationException(AppStrings.orderNotFound);
        }
        final currentStatus = OrderStatus.values.firstWhere(
          (status) => status.name == data['status'],
          orElse: () => OrderStatus.placed,
        );
        if (!_isAllowedOrderTransition(currentStatus, nextStatus)) {
          throw const AdminOperationException(
            AppStrings.invalidOrderTransition,
          );
        }
        final history =
            data['statusHistory'] is Iterable
                ? (data['statusHistory'] as Iterable)
                    .whereType<Map>()
                    .map((entry) => Map<String, dynamic>.from(entry))
                    .toList()
                : <Map<String, dynamic>>[];
        history.add(<String, dynamic>{
          'status': nextStatus.name,
          'timestamp': Timestamp.now(),
        });
        transaction.update(reference, <String, dynamic>{
          'status': nextStatus.name,
          'statusHistory': history,
        });
      });
    } on AdminOperationException {
      rethrow;
    } catch (error) {
      throw AdminOperationException(_friendlyError(error));
    }
  }

  static bool _isAllowedOrderTransition(OrderStatus current, OrderStatus next) {
    return switch (current) {
      OrderStatus.placed =>
        next == OrderStatus.shipped || next == OrderStatus.cancelled,
      OrderStatus.shipped =>
        next == OrderStatus.outForDelivery || next == OrderStatus.cancelled,
      OrderStatus.outForDelivery => next == OrderStatus.delivered,
      OrderStatus.delivered || OrderStatus.cancelled => false,
    };
  }

  Future<void> updateUserRole({
    required AppUser target,
    required UserRole role,
    required String actorUid,
  }) async {
    if (target.uid == actorUid && role != UserRole.admin) {
      throw const AdminOperationException(AppStrings.selfRoleChangeBlocked);
    }
    final users = _firestore.collection('users');
    final targetReference = users.doc(target.uid);
    try {
      final adminSnapshot =
          target.role == UserRole.admin && role != UserRole.admin
              ? await users.where('role', isEqualTo: UserRole.admin.name).get()
              : null;
      await _firestore.runTransaction<void>((transaction) async {
        if (adminSnapshot != null) {
          final adminDocs = adminSnapshot.docs;
          var adminCount = 0;
          for (final doc in adminDocs) {
            final current = await transaction.get(doc.reference);
            if (current.data()?['role'] == UserRole.admin.name) adminCount++;
          }
          if (adminCount <= 1) {
            throw const AdminOperationException(AppStrings.lastAdminBlocked);
          }
        } else {
          final current = await transaction.get(targetReference);
          if (!current.exists) {
            throw const AdminOperationException(AppStrings.profileNotFound);
          }
        }
        transaction.update(targetReference, <String, dynamic>{
          'role': role.name,
        });
      });
    } on AdminOperationException {
      rethrow;
    } catch (error) {
      throw AdminOperationException(_friendlyError(error));
    }
  }

  Future<void> setUserDisabled({
    required AppUser target,
    required bool disabled,
    required String actorUid,
  }) async {
    if (target.uid == actorUid && disabled) {
      throw const AdminOperationException(AppStrings.selfDisableBlocked);
    }
    try {
      await _firestore.collection('users').doc(target.uid).update(
        <String, dynamic>{'disabled': disabled},
      );
    } catch (error) {
      throw AdminOperationException(_friendlyError(error));
    }
  }

  static String _friendlyError(Object error) {
    return ErrorHandler.message(
      error,
      fallback: AppStrings.adminOperationFailed,
    );
  }

  @override
  void dispose() {
    unawaited(_usersSubscription?.cancel());
    unawaited(_ordersSubscription?.cancel());
    super.dispose();
  }
}

class AdminOperationException implements Exception, UserFacingError {
  const AdminOperationException(this.message);
  final String message;
  @override
  String get userMessage => message;

  @override
  String toString() => message;
}
