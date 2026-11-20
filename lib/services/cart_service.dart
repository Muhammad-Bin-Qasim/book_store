import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/book.dart';

class CartService {
  CartService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('carts').doc(uid).collection('items');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCart(String uid) =>
      _items(uid).snapshots();

  Future<void> addToCart(String uid, Book book, {int quantity = 1}) async {
    final reference = _items(uid).doc(book.id);
    final increment = quantity.clamp(1, 10).toInt();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final currentQuantity = snapshot.data()?['quantity'];
      final current = currentQuantity is num ? currentQuantity.toInt() : 0;
      transaction.set(reference, <String, dynamic>{
        'bookId': book.id,
        'quantity': (current + increment).clamp(1, 10).toInt(),
        'addedAt': snapshot.data()?['addedAt'] ?? FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateQuantity(String uid, String bookId, int quantity) async {
    if (quantity < 1 || quantity > 10) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be from 1 to 10.');
    }
    await _items(uid).doc(bookId).update(<String, dynamic>{
      'bookId': bookId,
      'quantity': quantity,
    });
  }

  Future<void> restoreItem(String uid, String bookId, int quantity) async {
    final safeQuantity = quantity.clamp(1, 10).toInt();
    await _items(uid).doc(bookId).set(<String, dynamic>{
      'bookId': bookId,
      'quantity': safeQuantity,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeItem(String uid, String bookId) =>
      _items(uid).doc(bookId).delete();

  Future<void> clearCart(String uid) async {
    final snapshot = await _items(uid).get();
    for (var start = 0; start < snapshot.docs.length; start += 450) {
      final batch = _firestore.batch();
      for (final document in snapshot.docs.skip(start).take(450)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  static String friendlyMessage(Object error) {
    return ErrorHandler.message(
      error,
      fallback: AppStrings.cartOperationFailed,
    );
  }
}
