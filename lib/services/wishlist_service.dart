import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';

class WishlistService {
  WishlistService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('wishlists').doc(uid).collection('items');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchWishlist(String uid) =>
      _items(uid).snapshots();

  Future<void> addToWishlist(String uid, String bookId) =>
      _items(uid).doc(bookId).set(<String, dynamic>{
        'bookId': bookId,
        'addedAt': FieldValue.serverTimestamp(),
      });

  Future<void> removeFromWishlist(String uid, String bookId) =>
      _items(uid).doc(bookId).delete();

  static String friendlyMessage(Object error) {
    return ErrorHandler.message(
      error,
      fallback: AppStrings.wishlistOperationFailed,
    );
  }
}
