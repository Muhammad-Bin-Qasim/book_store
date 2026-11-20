import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import 'admin_scaffold.dart';
import 'admin_ui.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  String _search = '';
  OrderStatus? _status;

  Future<void> _refresh() async {
    try {
      await context.read<AdminProvider>().refresh();
    } catch (_) {
      // The provider exposes the order-list error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: AppStrings.manageOrders,
      selectedIndex: 2,
      child: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final query = _search.trim().toLowerCase();
          final filtered = admin.orders
              .where((order) {
                final user = admin.userById(order.userId);
                final customer =
                    '${user?.name ?? ''} ${user?.email ?? ''}'.toLowerCase();
                final matchesQuery =
                    query.isEmpty ||
                    order.id.toLowerCase().contains(query) ||
                    customer.contains(query);
                return matchesQuery &&
                    (_status == null || order.status == _status);
              })
              .toList(growable: false);
          if (admin.errorMessage != null && !admin.hasLoaded) {
            return AdminErrorView(
              message: admin.errorMessage!,
              onRetry: _refresh,
            );
          }
          if (admin.isLoading && !admin.hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: <Widget>[
                        SizedBox(
                          width: wide ? 380 : constraints.maxWidth,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: AppStrings.searchOrders,
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged:
                                (value) => setState(() => _search = value),
                          ),
                        ),
                        SizedBox(
                          width: wide ? 240 : constraints.maxWidth,
                          child: DropdownButtonFormField<OrderStatus?>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: AppStrings.filterOrdersByStatus,
                            ),
                            items: <DropdownMenuItem<OrderStatus?>>[
                              const DropdownMenuItem<OrderStatus?>(
                                value: null,
                                child: Text(AppStrings.allStatuses),
                              ),
                              ...OrderStatus.values.map(
                                (status) => DropdownMenuItem<OrderStatus?>(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              ),
                            ],
                            onChanged:
                                (value) => setState(() => _status = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (filtered.isEmpty)
                      SizedBox(
                        height: 220,
                        child: Center(child: Text(AppStrings.noManagedOrders)),
                      )
                    else if (wide)
                      _OrdersTable(orders: filtered, onOpen: _openOrder)
                    else
                      ...filtered.map((order) {
                        final user = admin.userById(order.userId);
                        final customer =
                            user == null || user.name.isEmpty
                                ? user?.email ?? order.userId
                                : user.name;
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${AppStrings.orderShortIdLabel} #${_shortId(order.id)}',
                            ),
                            subtitle: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '$customer\n${DateFormat.yMMMd().format(order.createdAt)} · ',
                                  ),
                                  TextSpan(
                                    text: AppUtils.formatPrice(
                                      order.totalPrice,
                                    ),
                                    style: AppUtils.priceTextStyle(),
                                  ),
                                ],
                              ),
                            ),
                            isThreeLine: true,
                            trailing: AdminStatusChip(status: order.status),
                            onTap: () => _openOrder(order),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openOrder(Order order) => context.pushNamed(
    AppRoutes.adminOrderDetailsName,
    pathParameters: <String, String>{'id': order.id},
  );

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({required this.orders, required this.onOpen});
  final List<Order> orders;
  final ValueChanged<Order> onOpen;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text(AppStrings.orderId)),
          DataColumn(label: Text(AppStrings.customer)),
          DataColumn(label: Text(AppStrings.orderDate)),
          DataColumn(label: Text(AppStrings.total)),
          DataColumn(label: Text(AppStrings.orderStatus)),
        ],
        rows: orders
            .map((order) {
              final user = context.read<AdminProvider>().userById(order.userId);
              final customer =
                  user == null || user.name.isEmpty
                      ? user?.email ?? order.userId
                      : user.name;
              return DataRow(
                onSelectChanged: (_) => onOpen(order),
                cells: <DataCell>[
                  DataCell(Text(_shortId(order.id))),
                  DataCell(Text(customer)),
                  DataCell(Text(DateFormat.yMMMd().format(order.createdAt))),
                  DataCell(
                    Text(
                      AppUtils.formatPrice(order.totalPrice),
                      style: AppUtils.priceTextStyle(),
                    ),
                  ),
                  DataCell(AdminStatusChip(status: order.status)),
                ],
              );
            })
            .toList(growable: false),
      ),
    ),
  );

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}
