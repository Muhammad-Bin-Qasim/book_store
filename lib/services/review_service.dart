import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/review.dart';

class ReviewService {
  ReviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> _reviews(String bookId) =>
      _firestore.collection('books').doc(bookId).collection('reviews');

  Stream<List<Review>> streamBookReviews(String bookId) => _reviews(
    bookId,
  ).snapshots().map(
    (snapshot) => snapshot.docs
        .map(
          (document) =>
              Review.fromMap(document.data(), bookId: bookId, id: document.id),
        )
        .toList(growable: false),
  );

  Future<void> addOrUpdateReview({
    required String bookId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const ReviewServiceException(AppStrings.reviewInvalidRating);
    }
    final normalizedName = userName.trim();
    if (normalizedName.isEmpty || normalizedName.length > 80) {
      throw const ReviewServiceException(AppStrings.reviewNameValidation);
    }
    final normalizedComment = comment.trim();
    if (normalizedComment.length < 3 || normalizedComment.length > 500) {
      throw const ReviewServiceException(AppStrings.reviewCommentValidation);
    }
    final bookReference = _firestore.collection('books').doc(bookId);
    final reviewReference = _reviews(bookId).doc(userId);
    await _firestore.runTransaction<void>((transaction) async {
      final reviewQuery = await _reviews(bookId).get();
      final references = <DocumentReference<Map<String, dynamic>>>{
        for (final document in reviewQuery.docs) document.reference,
        reviewReference,
      };
      final bookSnapshot = await transaction.get(bookReference);
      if (!bookSnapshot.exists) {
        throw const ReviewServiceException(AppStrings.bookNotFound);
      }
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final reference in references) {
        snapshots.add(await transaction.get(reference));
      }
      final current = snapshots.firstWhere(
        (snapshot) => snapshot.reference.path == reviewReference.path,
        orElse: () => throw StateError(AppStrings.reviewCouldNotLoad),
      );
      final now = Timestamp.now();
      final currentData = current.data() ?? <String, dynamic>{};
      final reviewData = <String, dynamic>{
        'userId': userId,
        'userName': normalizedName,
        'rating': rating,
        'comment': normalizedComment,
        'likes':
            currentData['likes'] is num
                ? (currentData['likes'] as num).toInt()
                : 0,
        'likedBy':
            currentData['likedBy'] is Iterable
                ? List<String>.from(currentData['likedBy'] as Iterable)
                : <String>[],
        'createdAt': currentData['createdAt'] ?? now,
        'updatedAt': now,
      };
      final ratings = <double>[];
      for (final snapshot in snapshots) {
        if (snapshot.reference.path == reviewReference.path) {
          ratings.add(rating.toDouble());
          continue;
        }
        final data = snapshot.data();
        if (snapshot.exists && data != null) {
          final rawRating = data['rating'];
          if (rawRating is num && rawRating >= 1 && rawRating <= 5) {
            ratings.add(rawRating.toDouble());
          }
        }
      }
      transaction.set(reviewReference, reviewData);
      _writeAggregate(transaction, bookReference, ratings);
    });
  }

  Future<void> deleteReview({
    required String bookId,
    required String userId,
  }) async {
    final bookReference = _firestore.collection('books').doc(bookId);
    final reviewReference = _reviews(bookId).doc(userId);
    await _firestore.runTransaction<void>((transaction) async {
      final reviewQuery = await _reviews(bookId).get();
      final references = <DocumentReference<Map<String, dynamic>>>{
        for (final document in reviewQuery.docs) document.reference,
        reviewReference,
      };
      final bookSnapshot = await transaction.get(bookReference);
      if (!bookSnapshot.exists) {
        throw const ReviewServiceException(AppStrings.bookNotFound);
      }
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final reference in references) {
        snapshots.add(await transaction.get(reference));
      }
      final target = snapshots.firstWhere(
        (snapshot) => snapshot.reference.path == reviewReference.path,
        orElse: () => throw StateError(AppStrings.reviewCouldNotLoad),
      );
      if (!target.exists) return;
      final ratings = <double>[];
      for (final snapshot in snapshots) {
        if (snapshot.reference.path == reviewReference.path) continue;
        final rawRating = snapshot.data()?['rating'];
        if (snapshot.exists &&
            rawRating is num &&
            rawRating >= 1 &&
            rawRating <= 5) {
          ratings.add(rawRating.toDouble());
        }
      }
      transaction.delete(reviewReference);
      _writeAggregate(transaction, bookReference, ratings);
    });
  }

  Future<void> toggleLike({
    required String bookId,
    required String reviewId,
    required String userId,
  }) async {
    final reference = _reviews(bookId).doc(reviewId);
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const ReviewServiceException(AppStrings.reviewNotFound);
      }
      if (data['userId'] == userId) {
        throw const ReviewServiceException(AppStrings.reviewCannotLikeOwn);
      }
      final likedBy =
          data['likedBy'] is Iterable
              ? List<String>.from(data['likedBy'] as Iterable)
              : <String>[];
      final likes = data['likes'] is num ? (data['likes'] as num).toInt() : 0;
      final isLiked = likedBy.contains(userId);
      if (isLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      transaction.update(reference, <String, dynamic>{
        'likedBy': likedBy,
        'likes': isLiked ? (likes - 1).clamp(0, likes) : likes + 1,
      });
    });
  }

  void _writeAggregate(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> bookReference,
    List<double> ratings,
  ) {
    final average =
        ratings.isEmpty
            ? 0.0
            : ratings.reduce((left, right) => left + right) / ratings.length;
    transaction.update(bookReference, <String, dynamic>{
      'avgRating': average,
      'ratingCount': ratings.length,
    });
  }

  static String friendlyMessage(Object error) {
    return ErrorHandler.message(error, fallback: AppStrings.reviewSaveFailed);
  }
}

class ReviewServiceException implements Exception, UserFacingError {
  const ReviewServiceException(this.message);
  final String message;
  @override
  String get userMessage => message;

  @override
  String toString() => message;
}
