import '../core/app_utils.dart';

class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.likes,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory Review.fromMap(Map<String, dynamic> map,
      {required String bookId, String? id}) {
    final created = AppUtils.dateTimeFromValue(map['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return Review(
      id: id ?? map['id'] as String? ?? '',
      bookId: bookId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      rating: AppUtils.toDouble(map['rating']),
      comment: map['comment'] as String? ?? '',
      likes: AppUtils.toInt(map['likes']),
      likedBy: AppUtils.stringList(map['likedBy']),
      createdAt: created,
      updatedAt: AppUtils.dateTimeFromValue(map['updatedAt']) ?? created,
    );
  }

  Review copyWith({
    String? userName,
    double? rating,
    String? comment,
    int? likes,
    List<String>? likedBy,
    DateTime? updatedAt,
  }) =>
      Review(
        id: id,
        bookId: bookId,
        userId: userId,
        userName: userName ?? this.userName,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
