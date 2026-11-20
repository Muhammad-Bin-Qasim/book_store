import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/staggered_entrance.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Set<String> _playedItems = <String>{};

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.orderHistory)),
      body:
          orders.isLoading
              ? const OrderListSkeleton()
              : orders.errorMessage != null
              ? ErrorView(
                title: AppStrings.errorTitle,
                message: orders.errorMessage,
                onRetry: orders.retry,
              )
              : orders.orders.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: AppStrings.noOrdersTitle,
                      message: AppStrings.noOrdersMessage,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => context.goNamed(AppRoutes.homeName),
                      child: const Text(AppStrings.browseBooks),
                    ),
                  ],
                ),
              )
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: orders.orders.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final order = orders.orders[index];
                      return StaggeredEntrance(
                        key: ValueKey<String>('order-${order.id}'),
                        itemId: 'order-${order.id}',
                        index: index,
                        playedItemIds: _playedItems,
                        child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap:
                              () => context.pushNamed(
                                AppRoutes.orderDetailsName,
                                pathParameters: <String, String>{
                                  'id': order.id,
                                },
                              ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${AppStrings.orderShortIdLabel} #${_shortId(order.id)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    _StatusChip(status: order.status),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  DateFormat.yMMMd().format(order.createdAt),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppStrings.itemCountFormat(
                                          order.itemCount,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      AppUtils.formatPrice(order.totalPrice),
                                      style: AppUtils.priceTextStyle(
                                        baseStyle: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                ),
              ),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      OrderStatus.placed => scheme.primaryContainer,
      OrderStatus.shipped => scheme.secondaryContainer,
      OrderStatus.outForDelivery => scheme.tertiaryContainer,
      OrderStatus.delivered => scheme.primary,
      OrderStatus.cancelled => scheme.errorContainer,
    };
    final foreground =
        status == OrderStatus.delivered
            ? scheme.onPrimary
            : status == OrderStatus.cancelled
            ? scheme.onErrorContainer
            : scheme.onSurface;
    return Chip(
      label: Text(status.label, style: TextStyle(color: foreground)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
