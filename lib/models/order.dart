import '../core/app_constants.dart';
import '../core/app_utils.dart';
import 'cart_item.dart';

enum OrderStatus { placed, shipped, outForDelivery, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => AppStrings.statusPlaced,
        OrderStatus.shipped => AppStrings.statusShipped,
        OrderStatus.outForDelivery => AppStrings.statusOutForDelivery,
        OrderStatus.delivered => AppStrings.statusDelivered,
        OrderStatus.cancelled => AppStrings.statusCancelled,
      };
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.statusHistory,
    required this.createdAt,
    required this.estimatedDelivery,
    required this.shippingAddress,
    required this.paymentMethod,
  });

  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final OrderStatus status;
  final List<Map<String, dynamic>> statusHistory;
  final DateTime createdAt;
  final DateTime estimatedDelivery;
  final Map<String, dynamic> shippingAddress;
  final Map<String, dynamic> paymentMethod;

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  DateTime? timestampFor(OrderStatus value) {
    for (final event in statusHistory) {
      if (event['status'] == value.name) {
        return AppUtils.dateTimeFromValue(event['timestamp']);
      }
    }
    return null;
  }

  Order appendStatusChange(OrderStatus value, {DateTime? timestamp}) {
    return copyWith(
      status: value,
      statusHistory: <Map<String, dynamic>>[
        ...statusHistory,
        <String, dynamic>{
          'status': value.name,
          'timestamp': timestamp ?? DateTime.now(),
        },
      ],
    );
  }

  factory Order.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawItems = map['items'];
    final items = rawItems is Iterable
        ? rawItems.whereType<Map>().map((raw) {
            final item = Map<String, dynamic>.from(raw);
            return CartItem.fromMap(item, id: item['bookId'] as String?);
          }).toList(growable: false)
        : <CartItem>[];
    final rawHistory = map['statusHistory'];
    final history = rawHistory is Iterable
        ? rawHistory
            .whereType<Map>()
            .map((event) => Map<String, dynamic>.from(event))
            .toList(growable: false)
        : <Map<String, dynamic>>[];
    final rawStatus = map['status'] as String?;
    final status = OrderStatus.values.firstWhere(
      (value) => value.name == rawStatus,
      orElse: () => OrderStatus.placed,
    );
    return Order(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      items: items,
      totalPrice: AppUtils.toDouble(map['totalPrice']),
      status: status,
      statusHistory: history,
      createdAt: AppUtils.dateTimeFromValue(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      estimatedDelivery:
          AppUtils.dateTimeFromValue(map['estimatedDelivery']) ??
              DateTime.fromMillisecondsSinceEpoch(0),
      shippingAddress: _map(map['shippingAddress']),
      paymentMethod: _map(map['paymentMethod']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'items': items
            .map((item) => <String, dynamic>{
                  'bookId': item.bookId,
                  'title': item.title,
                  'author': item.author,
                  'coverUrl': item.coverUrl,
                  'unitPrice': item.price,
                  'quantity': item.quantity,
                })
            .toList(growable: false),
        'totalPrice': totalPrice,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'status': status.name,
        'statusHistory': statusHistory,
        'createdAt': createdAt,
        'estimatedDelivery': estimatedDelivery,
      };

  Order copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? totalPrice,
    OrderStatus? status,
    List<Map<String, dynamic>>? statusHistory,
    DateTime? createdAt,
    DateTime? estimatedDelivery,
    Map<String, dynamic>? shippingAddress,
    Map<String, dynamic>? paymentMethod,
  }) =>
      Order(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        items: items ?? this.items,
        totalPrice: totalPrice ?? this.totalPrice,
        status: status ?? this.status,
        statusHistory: statusHistory ?? this.statusHistory,
        createdAt: createdAt ?? this.createdAt,
        estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
        shippingAddress: shippingAddress ?? this.shippingAddress,
        paymentMethod: paymentMethod ?? this.paymentMethod,
      );

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
}
