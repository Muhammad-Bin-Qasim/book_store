import '../core/app_utils.dart';

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final DateTime createdAt;

  factory WishlistItem.fromMap(Map<String, dynamic> map, {String? id}) {
    return WishlistItem(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      createdAt: AppUtils.dateTimeFromValue(map['addedAt'] ?? map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'bookId': bookId,
        'addedAt': createdAt,
      };

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? bookId,
    DateTime? createdAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
