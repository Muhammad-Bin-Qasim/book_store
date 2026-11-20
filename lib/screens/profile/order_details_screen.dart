import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_utils.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/book_thumb.dart';
import '../../widgets/design_system.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({required this.orderId, super.key});
  final String orderId;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Stream<Order?> _orderStream;
  StreamSubscription<Order?>? _statusSubscription;
  OrderStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _orderStream = context.read<OrderProvider>().watchOrderById(widget.orderId);
    _listenForStatusChanges();
  }

  void _listenForStatusChanges() {
    _statusSubscription = _orderStream.listen((order) {
      if (order == null) return;
      final previous = _lastStatus;
      _lastStatus = order.status;
      if (previous != null && previous != order.status && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppStrings.orderStatusUpdated(order.status.label)),
            ),
          );
      }
    }, onError: (Object _) {});
  }

  void _retry() {
    final nextStream = context.read<OrderProvider>().watchOrderById(
      widget.orderId,
    );
    unawaited(_statusSubscription?.cancel());
    setState(() => _orderStream = nextStream);
    _listenForStatusChanges();
  }

  @override
  void dispose() {
    unawaited(_statusSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.orderDetails)),
    body: StreamBuilder<Order?>(
      stream: _orderStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(
            title: AppStrings.orderIdUnavailable,
            message: OrderService.friendlyMessage(snapshot.error!),
            onRetry: _retry,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        final order = snapshot.data;
        if (order == null) {
          return ErrorView(
            title: AppStrings.orderIdUnavailable,
            onRetry: _retry,
          );
        }
        return _OrderDetailsContent(order: order);
      },
    ),
  );
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.orderShortIdLabel} #${_shortId(order.id)}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppStrings.orderDate}: ${DateFormat.yMMMd().format(order.createdAt)}',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppStrings.estimatedDelivery}: ${DateFormat.yMMMd().format(order.estimatedDelivery)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusPill(status: order.status),
                  ],
                ),
              ),
            ),
            if (order.status == OrderStatus.cancelled)
              Card(
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.cancel_outlined,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  title: Text(
                    AppStrings.orderCancelledMessage,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              )
            else
              _TrackingTimeline(order: order),
            _DetailCard(
              title: AppStrings.orderItems,
              child: Column(
                children: order.items
                    .map((item) => _OrderItemTile(item: item))
                    .toList(growable: false),
              ),
            ),
            _DetailCard(
              title: AppStrings.shippingAddress,
              child: Text(_addressText(order.shippingAddress)),
            ),
            _DetailCard(
              title: AppStrings.paymentSummary,
              child: Text(_paymentText(order.paymentMethod)),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.total, style: theme.textTheme.titleMedium),
                    Text(
                      AppUtils.formatPrice(order.totalPrice),
                      style: AppUtils.priceTextStyle(
                        baseStyle: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (order.status == OrderStatus.placed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(context),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(AppStrings.cancelOrder),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text(AppStrings.cancelOrderConfirmationTitle),
                content: const Text(AppStrings.cancelOrderConfirmationMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(AppStrings.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text(AppStrings.cancelOrder),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<OrderProvider>().cancelOrder(order.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderCancelSuccess)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(OrderService.friendlyMessage(error))),
      );
    }
  }

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

  String _addressText(Map<String, dynamic> address) => <String>[
    '${address['fullName'] ?? ''}',
    '${address['phone'] ?? ''}',
    '${address['addressLine'] ?? ''}',
    '${address['city'] ?? ''} ${address['postalCode'] ?? ''}'.trim(),
  ].where((part) => part.trim().isNotEmpty).join('\n');

  String _paymentText(Map<String, dynamic> payment) {
    final type = payment['type'] as String? ?? AppStrings.cashOnDelivery;
    final last4 = payment['last4'] as String? ?? '';
    return type == AppStrings.card && last4.isNotEmpty
        ? '$type · ${AppStrings.paymentCardEnding} $last4'
        : type;
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        BookThumb(
          url: item.coverUrl,
          width: 48,
          height: 64,
          borderRadius: AppRadii.sm,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${item.author} · ${AppStrings.quantity}: ${item.quantity}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          AppUtils.formatPrice(item.price * item.quantity),
          style: AppUtils.priceTextStyle(),
        ),
      ],
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.order});
  final Order order;

  int get _currentStep => switch (order.status) {
    OrderStatus.placed => 0,
    OrderStatus.shipped => 2,
    OrderStatus.outForDelivery => 2,
    OrderStatus.delivered => 3,
    OrderStatus.cancelled => 0,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestTimestamp = order.timestampFor(order.status);
    return _DetailCard(
      title: AppStrings.orderTracking,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepTimeline(
            steps: const [
              AppStrings.statusPlaced,
              AppStrings.statusProcessing,
              AppStrings.statusShipped,
              AppStrings.statusDelivered,
            ],
            currentStep: _currentStep,
          ),
          if (latestTimestamp != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    AppStrings.orderStatusAt(
                      order.status.label,
                      DateFormat.yMMMd().add_jm().format(latestTimestamp),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '${AppStrings.estimatedDelivery}: ${DateFormat.yMMMd().format(order.estimatedDelivery)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    if (status != OrderStatus.cancelled) {
      return StatusChip(label: status.label);
    }
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        Icons.cancel_outlined,
        color: theme.colorScheme.onErrorContainer,
        size: 18,
      ),
      label: Text(
        status.label,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
      backgroundColor: theme.colorScheme.errorContainer,
      side: BorderSide.none,
    );
  }
}
