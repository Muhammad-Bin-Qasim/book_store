import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderService? orderService})
    : _orderService = orderService ?? OrderService();

  final OrderService _orderService;
  StreamSubscription<List<Order>>? _subscription;
  String? _userId;
  List<Order> _orders = const <Order>[];
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  String? _errorMessage;

  List<Order> get orders => List<Order>.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get errorMessage => _errorMessage;

  void bind(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _orders = const <Order>[];
    _errorMessage = null;
    _isLoading = userId != null;
    notifyListeners();
    if (userId == null) return;
    _subscription = _orderService
        .streamUserOrders(userId)
        .listen(
          (orders) {
            if (_userId != userId) return;
            _orders = orders;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (_userId != userId) return;
            _isLoading = false;
            _errorMessage = ErrorHandler.message(
              error,
              fallback: AppStrings.orderOperationFailed,
            );
            notifyListeners();
          },
        );
  }

  void retry() {
    final uid = _userId;
    if (uid == null) return;
    unawaited(_subscription?.cancel());
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _subscription = _orderService
        .streamUserOrders(uid)
        .listen(
          (orders) {
            if (_userId != uid) return;
            _orders = orders;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (_userId != uid) return;
            _isLoading = false;
            _errorMessage = ErrorHandler.message(
              error,
              fallback: AppStrings.orderOperationFailed,
            );
            notifyListeners();
          },
        );
  }

  Future<PlaceOrderResult> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required Map<String, dynamic> paymentMethod,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw const OrderServiceException(AppStrings.loginRequiredForOrders);
    }
    if (_isPlacingOrder) {
      throw const OrderServiceException(AppStrings.orderAlreadyPlacing);
    }
    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _orderService.placeOrder(
        userId: userId,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
      );
    } catch (error) {
      _errorMessage = ErrorHandler.message(
        error,
        fallback: AppStrings.orderOperationFailed,
      );
      throw OrderServiceException(_errorMessage!);
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final userId = _userId;
    if (userId == null) {
      throw const OrderServiceException(AppStrings.loginRequiredForOrders);
    }
    try {
      await _orderService.cancelOrder(orderId, userId);
    } catch (error) {
      throw OrderServiceException(
        ErrorHandler.message(error, fallback: AppStrings.orderOperationFailed),
      );
    }
  }

  Stream<Order?> watchOrderById(String orderId) =>
      _orderService.streamOrderById(orderId);

  Future<Order?> getOrderById(String orderId) =>
      _orderService.getOrderById(orderId);

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
