import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/order.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> _cartItems(String userId) =>
      _firestore.collection('carts').doc(userId).collection('items');

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection('books');

  Future<PlaceOrderResult> placeOrder({
    required String userId,
    required Map<String, dynamic> shippingAddress,
    required Map<String, dynamic> paymentMethod,
  }) async {
    try {
      final cartSnapshot = await _cartItems(userId).get();
      if (cartSnapshot.docs.isEmpty) {
        throw const OrderServiceException(AppStrings.cartEmptyTitle);
      }
      final cartReferences = cartSnapshot.docs
          .map((document) => document.reference)
          .toList(growable: false);
      final orderReference = _orders.doc();
      final placedAt = DateTime.now();
      final estimatedDelivery = placedAt.add(const Duration(days: 5));
      final result = await _firestore.runTransaction<PlaceOrderResult>((
        transaction,
      ) async {
        final cartDocuments = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final reference in cartReferences) {
          cartDocuments.add(await transaction.get(reference));
        }
        final bookReferences =
            <String, DocumentReference<Map<String, dynamic>>>{};
        for (final cartDocument in cartDocuments) {
          if (!cartDocument.exists) continue;
          final id =
              cartDocument.data()?['bookId'] as String? ?? cartDocument.id;
          bookReferences[id] = _books.doc(id);
        }
        final bookDocuments =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final entry in bookReferences.entries) {
          bookDocuments[entry.key] = await transaction.get(entry.value);
        }

        final orderItems = <Map<String, dynamic>>[];
        final missingBookIds = <String>[];
        var total = 0.0;
        for (final cartDocument in cartDocuments) {
          final cartData = cartDocument.data();
          if (cartData == null) continue;
          final bookId = cartData['bookId'] as String? ?? cartDocument.id;
          final bookSnapshot = bookDocuments[bookId];
          final bookData = bookSnapshot?.data();
          if (bookSnapshot?.exists != true || bookData == null) {
            missingBookIds.add(bookId);
            continue;
          }
          final rawQuantity = cartData['quantity'];
          final quantity = rawQuantity is num ? rawQuantity.toInt() : 1;
          final safeQuantity = quantity.clamp(1, 10).toInt();
          final rawPrice = bookData['price'];
          if (rawPrice is! num || !rawPrice.isFinite || rawPrice < 0) {
            throw const OrderServiceException(AppStrings.orderInvalidPrice);
          }
          final unitPrice = rawPrice.toDouble();
          orderItems.add(<String, dynamic>{
            'bookId': bookId,
            'title': bookData['title'] as String? ?? AppStrings.unavailableBook,
            'author': bookData['author'] as String? ?? '',
            'coverUrl': bookData['coverUrl'] as String? ?? '',
            'unitPrice': unitPrice,
            'quantity': safeQuantity,
          });
          total += unitPrice * safeQuantity;
        }

        for (final reference in cartReferences) {
          transaction.delete(reference);
        }
        if (orderItems.isEmpty) {
          return PlaceOrderResult(
            orderId: null,
            totalPrice: 0,
            estimatedDelivery: null,
            unavailableBookIds: missingBookIds,
          );
        }

        final addressSnapshot = Map<String, dynamic>.from(shippingAddress);
        addressSnapshot.remove('isDefault');
        final savedPayment = <String, dynamic>{
          'type': paymentMethod['type'] as String? ?? AppStrings.cashOnDelivery,
          'last4': paymentMethod['last4'] as String? ?? '',
        };
        transaction.set(orderReference, <String, dynamic>{
          'userId': userId,
          'items': orderItems,
          'totalPrice': total,
          'shippingAddress': addressSnapshot,
          'paymentMethod': savedPayment,
          'status': OrderStatus.placed.name,
          'statusHistory': <Map<String, dynamic>>[
            <String, dynamic>{
              'status': OrderStatus.placed.name,
              'timestamp': Timestamp.fromDate(placedAt),
            },
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'estimatedDelivery': Timestamp.fromDate(estimatedDelivery),
        });
        return PlaceOrderResult(
          orderId: orderReference.id,
          totalPrice: total,
          estimatedDelivery: estimatedDelivery,
          unavailableBookIds: missingBookIds,
        );
      });
      return result;
    } on FirebaseException catch (error) {
      throw OrderServiceException(_messageForCode(error.code));
    }
  }

  Stream<List<Order>> streamUserOrders(String userId) =>
      _orders.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
        final orders =
            snapshot.docs
                .map(
                  (document) => Order.fromMap(document.data(), id: document.id),
                )
                .toList();
        orders.sort((left, right) => right.createdAt.compareTo(left.createdAt));
        return List<Order>.unmodifiable(orders);
      });

  Future<Order?> getOrderById(String orderId) async {
    try {
      final snapshot = await _orders.doc(orderId).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Order.fromMap(data, id: snapshot.id);
    } on FirebaseException catch (error) {
      throw OrderServiceException(_messageForCode(error.code));
    }
  }

  Stream<Order?> streamOrderById(String orderId) =>
      _orders.doc(orderId).snapshots().map((snapshot) {
        final data = snapshot.data();
        return snapshot.exists && data != null
            ? Order.fromMap(data, id: snapshot.id)
            : null;
      });

  Future<void> cancelOrder(String orderId, String userId) async {
    try {
      final reference = _orders.doc(orderId);
      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data();
        if (!snapshot.exists || data == null || data['userId'] != userId) {
          throw const OrderServiceException(AppStrings.orderNotFound);
        }
        if (data['status'] != OrderStatus.placed.name) {
          throw const OrderServiceException(AppStrings.orderCannotCancel);
        }
        final history =
            data['statusHistory'] is Iterable
                ? (data['statusHistory'] as Iterable)
                    .whereType<Map>()
                    .map((event) => Map<String, dynamic>.from(event))
                    .toList()
                : <Map<String, dynamic>>[];
        history.add(<String, dynamic>{
          'status': OrderStatus.cancelled.name,
          'timestamp': Timestamp.now(),
        });
        transaction.update(reference, <String, dynamic>{
          'status': OrderStatus.cancelled.name,
          'statusHistory': history,
        });
      });
    } on FirebaseException catch (error) {
      throw OrderServiceException(_messageForCode(error.code));
    }
  }

  static String friendlyMessage(Object error) =>
      ErrorHandler.message(error, fallback: AppStrings.orderOperationFailed);

  static String _messageForCode(String code) => ErrorHandler.message(
    FirebaseException(plugin: 'cloud_firestore', code: code),
    fallback: AppStrings.orderOperationFailed,
  );
}

class PlaceOrderResult {
  const PlaceOrderResult({
    required this.orderId,
    required this.totalPrice,
    required this.estimatedDelivery,
    required this.unavailableBookIds,
  });

  final String? orderId;
  final double totalPrice;
  final DateTime? estimatedDelivery;
  final List<String> unavailableBookIds;
}

class OrderServiceException implements Exception, UserFacingError {
  const OrderServiceException(this.message);
  final String message;
  @override
  String get userMessage => message;

  @override
  String toString() => message;
}
