import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import 'admin_scaffold.dart';
import 'admin_ui.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  const AdminOrderDetailsScreen({required this.orderId, super.key});
  final String orderId;

  @override
  Widget build(BuildContext context) => AdminScaffold(
    title: AppStrings.orderDetails,
    selectedIndex: 2,
    child: Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final matches = admin.orders.where((order) => order.id == orderId);
        if (matches.isEmpty) {
          if (admin.isLoading && !admin.hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return AdminErrorView(
            message: admin.errorMessage ?? AppStrings.orderIdUnavailable,
            onRetry: () => admin.refresh().catchError((_) {}),
          );
        }
        return _OrderAdminContent(order: matches.first);
      },
    ),
  );
}

class _OrderAdminContent extends StatelessWidget {
  const _OrderAdminContent({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AdminProvider>().userById(order.userId);
    final address = order.shippingAddress;
    final payment = order.paymentMethod;
    final history =
        order.statusHistory.toList()..sort((a, b) {
          final left =
              AppUtils.dateTimeFromValue(a['timestamp']) ?? DateTime(1970);
          final right =
              AppUtils.dateTimeFromValue(b['timestamp']) ?? DateTime(1970);
          return left.compareTo(right);
        });
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '${AppStrings.orderShortIdLabel} #${order.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${AppStrings.orderDate}: ${DateFormat.yMMMd().format(order.createdAt)}',
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${AppStrings.orderItemsTotal}: '),
                          TextSpan(
                            text: AppUtils.formatPrice(order.totalPrice),
                            style: AppUtils.priceTextStyle(),
                          ),
                        ],
                      ),
                    ),
                    AdminStatusChip(status: order.status),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.orderCustomer,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user?.name.isNotEmpty == true
                          ? user!.name
                          : AppStrings.accountNameUnavailable,
                    ),
                    Text(user?.email ?? order.userId),
                    Text(
                      '${AppStrings.role}: ${user?.role == null ? AppStrings.userRole : _roleName(user!.role)}',
                    ),
                  ],
                ),
              ),
            ),
            _Section(
              title: AppStrings.orderItems,
              child: Column(
                children: order.items
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 48,
                          height: 64,
                          child:
                              item.coverUrl.isEmpty
                                  ? const Icon(Icons.menu_book_outlined)
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: item.coverUrl,
                                      fit: BoxFit.cover,
                                      errorWidget:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                    ),
                                  ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.author} · ${AppStrings.quantity}: ${item.quantity}',
                        ),
                        trailing: Text(
                          AppUtils.formatPrice(item.price * item.quantity),
                          style: AppUtils.priceTextStyle(),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            _Section(
              title: AppStrings.shippingAddress,
              child: Text(
                <String>[
                  '${address['fullName'] ?? ''}',
                  '${address['phone'] ?? ''}',
                  '${address['addressLine'] ?? ''}',
                  '${address['city'] ?? ''} ${address['postalCode'] ?? ''}'
                      .trim(),
                ].where((line) => line.trim().isNotEmpty).join('\n'),
              ),
            ),
            _Section(
              title: AppStrings.paymentSummary,
              child: Text(
                '${payment['type'] ?? AppStrings.cashOnDelivery}${(payment['last4'] as String? ?? '').isEmpty ? '' : ' · ${AppStrings.paymentCardEnding} ${payment['last4']}'}',
              ),
            ),
            _Section(
              title: AppStrings.orderTracking,
              child: Column(
                children: history
                    .map((event) {
                      final status = OrderStatus.values.firstWhere(
                        (value) => value.name == event['status'],
                        orElse: () => OrderStatus.placed,
                      );
                      final timestamp = AppUtils.dateTimeFromValue(
                        event['timestamp'],
                      );
                      return ListTile(
                        leading: const Icon(Icons.circle_outlined),
                        title: Text(status.label),
                        subtitle:
                            timestamp == null
                                ? null
                                : Text(
                                  DateFormat.yMMMd().add_jm().format(timestamp),
                                ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            if (_availableNextStatuses(order.status).isNotEmpty)
              _Section(
                title: AppStrings.updateOrderStatus,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _availableNextStatuses(order.status)
                      .map(
                        (status) => OutlinedButton.icon(
                          onPressed: () => _changeStatus(context, status),
                          icon: const Icon(Icons.update_rounded),
                          label: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<OrderStatus> _availableNextStatuses(OrderStatus current) =>
      switch (current) {
        OrderStatus.placed => <OrderStatus>[
          OrderStatus.shipped,
          OrderStatus.cancelled,
        ],
        OrderStatus.shipped => <OrderStatus>[
          OrderStatus.outForDelivery,
          OrderStatus.cancelled,
        ],
        OrderStatus.outForDelivery => <OrderStatus>[OrderStatus.delivered],
        OrderStatus.delivered || OrderStatus.cancelled => <OrderStatus>[],
      };

  Future<void> _changeStatus(BuildContext context, OrderStatus status) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text(AppStrings.confirmStatusChange),
                content: Text(
                  '${AppStrings.statusChangeConfirmation}\n${status.label}',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(AppStrings.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(status.label),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<AdminProvider>().updateOrderStatus(order.id, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderStatusSaved)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(
              error,
              fallback: AppStrings.adminOperationFailed,
            ),
          ),
        ),
      );
    }
  }

  String _roleName(UserRole role) =>
      role == UserRole.admin ? AppStrings.adminRole : AppStrings.userRole;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}
