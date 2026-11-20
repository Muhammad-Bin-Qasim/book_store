import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/review.dart';
import '../services/review_service.dart';

enum ReviewSortOption { newest, mostLiked }

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewService? reviewService})
    : _reviewService = reviewService ?? ReviewService();

  final ReviewService _reviewService;
  final Map<String, StreamSubscription<List<Review>>> _subscriptions = {};
  final Map<String, List<Review>> _reviews = {};
  final Map<String, String?> _errors = {};
  final Map<String, bool> _loading = {};
  final Map<String, int> _openCounts = {};
  String? _userId;
  ReviewSortOption _sortOption = ReviewSortOption.newest;

  String? get userId => _userId;
  ReviewSortOption get sortOption => _sortOption;
  List<Review> reviewsFor(String bookId) =>
      List<Review>.unmodifiable(_reviews[bookId] ?? const <Review>[]);
  bool isLoading(String bookId) => _loading[bookId] ?? true;
  String? errorFor(String bookId) => _errors[bookId];

  List<Review> sortedReviewsFor(String bookId) {
    final items = List<Review>.from(_reviews[bookId] ?? const <Review>[]);
    switch (_sortOption) {
      case ReviewSortOption.newest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ReviewSortOption.mostLiked:
        items.sort((a, b) {
          final byLikes = b.likes.compareTo(a.likes);
          return byLikes != 0 ? byLikes : b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    return items;
  }

  Review? myReviewFor(String bookId) {
    final uid = _userId;
    if (uid == null) return null;
    for (final review in _reviews[bookId] ?? const <Review>[]) {
      if (review.userId == uid) return review;
    }
    return null;
  }

  void bind(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    notifyListeners();
  }

  void openBook(String bookId) {
    _openCounts.update(bookId, (value) => value + 1, ifAbsent: () => 1);
    if (_subscriptions.containsKey(bookId)) return;
    _loading[bookId] = true;
    _errors[bookId] = null;
    _subscriptions[bookId] = _reviewService
        .streamBookReviews(bookId)
        .listen(
          (reviews) {
            _reviews[bookId] = reviews;
            _loading[bookId] = false;
            _errors[bookId] = null;
            notifyListeners();
          },
          onError: (Object error) {
            _loading[bookId] = false;
            _errors[bookId] = ErrorHandler.message(
              error,
              fallback: AppStrings.reviewSaveFailed,
            );
            notifyListeners();
          },
        );
    notifyListeners();
  }

  void closeBook(String bookId) {
    final count = _openCounts[bookId] ?? 0;
    if (count > 1) {
      _openCounts[bookId] = count - 1;
      return;
    }
    _openCounts.remove(bookId);
    unawaited(_subscriptions.remove(bookId)?.cancel());
    _reviews.remove(bookId);
    _errors.remove(bookId);
    _loading.remove(bookId);
  }

  void retry(String bookId) {
    unawaited(_subscriptions.remove(bookId)?.cancel());
    _openCounts[bookId] = 0;
    _reviews.remove(bookId);
    openBook(bookId);
  }

  void setSortOption(ReviewSortOption value) {
    if (_sortOption == value) return;
    _sortOption = value;
    notifyListeners();
  }

  Future<void> addOrUpdateReview({
    required String bookId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    final uid = _requireUser();
    await _reviewService.addOrUpdateReview(
      bookId: bookId,
      userId: uid,
      userName: userName,
      rating: rating,
      comment: comment,
    );
  }

  Future<void> deleteReview(String bookId) async {
    await _reviewService.deleteReview(bookId: bookId, userId: _requireUser());
  }

  Future<void> toggleLike(String bookId, Review review) async {
    final uid = _requireUser();
    if (review.userId == uid) {
      throw const ReviewServiceException(AppStrings.reviewCannotLikeOwn);
    }
    final reviews = List<Review>.from(_reviews[bookId] ?? const <Review>[]);
    final index = reviews.indexWhere((item) => item.id == review.id);
    if (index < 0) return;
    final previous = reviews[index];
    final likedBy = List<String>.from(previous.likedBy);
    final isLiked = likedBy.contains(uid);
    if (isLiked) {
      likedBy.remove(uid);
    } else {
      likedBy.add(uid);
    }
    reviews[index] = previous.copyWith(
      likedBy: likedBy,
      likes:
          isLiked
              ? (previous.likes - 1).clamp(0, previous.likes)
              : previous.likes + 1,
    );
    _reviews[bookId] = reviews;
    notifyListeners();
    try {
      await _reviewService.toggleLike(
        bookId: bookId,
        reviewId: review.id,
        userId: uid,
      );
    } catch (error) {
      final current = List<Review>.from(_reviews[bookId] ?? const <Review>[]);
      final currentIndex = current.indexWhere((item) => item.id == review.id);
      if (currentIndex >= 0) current[currentIndex] = previous;
      _reviews[bookId] = current;
      notifyListeners();
      throw ReviewServiceException(
        ErrorHandler.message(error, fallback: AppStrings.reviewSaveFailed),
      );
    }
  }

  String _requireUser() {
    final uid = _userId;
    if (uid == null) {
      throw const ReviewServiceException(AppStrings.loginRequiredForReviews);
    }
    return uid;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
