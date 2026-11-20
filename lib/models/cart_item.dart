import '../core/app_utils.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.price,
    required this.quantity,
    this.unavailable = false,
  });

  final String id;
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final double price;
  final int quantity;
  final bool unavailable;

  factory CartItem.fromMap(Map<String, dynamic> map, {String? id}) {
    return CartItem(
      id: id ?? map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      price: AppUtils.toDouble(map['unitPrice'] ?? map['price']),
      quantity: AppUtils.toInt(map['quantity'], fallback: 1),
      unavailable: map['unavailable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookId': bookId,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'price': price,
        'quantity': quantity,
        'unavailable': unavailable,
      };

  CartItem copyWith({
    String? id,
    String? bookId,
    String? title,
    String? author,
    String? coverUrl,
    double? price,
    int? quantity,
    bool? unavailable,
  }) {
    return CartItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unavailable: unavailable ?? this.unavailable,
    );
  }
}
