import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/book_provider.dart';
import '../../services/book_service.dart';
import 'admin_scaffold.dart';
import 'admin_ui.dart';
import '../../widgets/design_system.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final tasks = <Future<void>>[
      context.read<BookProvider>().refresh(),
      context.read<AdminProvider>().refresh(),
    ];
    try {
      await Future.wait(tasks);
    } catch (_) {
      // Providers expose their own error states for the page.
    }
  }

  Future<void> _seedCatalog() async {
    setState(() => _isSeeding = true);
    try {
      final added = await context.read<BookProvider>().seedSampleBooks();
      if (!mounted) return;
      if (added) await context.read<BookProvider>().refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? AppStrings.seedSuccess : AppStrings.seedSkipped,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(BookService.friendlyMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: AppStrings.adminDashboard,
      selectedIndex: 0,
      child: Consumer2<BookProvider, AdminProvider>(
        builder: (context, books, admin, _) {
          final error = books.errorMessage ?? admin.errorMessage;
          if (error != null &&
              ((books.errorMessage != null && !books.hasLoaded) ||
                  (admin.errorMessage != null && !admin.hasLoaded))) {
            return AdminErrorView(message: error, onRetry: _refresh);
          }
          if ((books.isLoading && !books.hasLoaded) ||
              (admin.isLoading && !admin.hasLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }
          final revenue = admin.orders
              .where((order) => order.status != OrderStatus.cancelled)
              .fold<double>(0, (sum, order) => sum + order.totalPrice);
          final statusCounts = <OrderStatus, int>{
            for (final status in OrderStatus.values)
              status: admin.orders
                  .where((order) => order.status == status)
                  .length,
          };
          final lowRated = books.allBooks
              .where((book) => book.avgRating < 3)
              .length;
          final recent = admin.orders.take(5).toList(growable: false);
          final popular = books.allBooks.toList()
            ..sort((a, b) => b.popularity.compareTo(a.popularity));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isSeeding ? null : _seedCatalog,
                    icon: _isSeeding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.library_add_rounded),
                    label: const Text(AppStrings.seedSampleBooks),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 900
                        ? (constraints.maxWidth - AppSpacing.md * 3) / 4
                        : constraints.maxWidth >= 560
                        ? (constraints.maxWidth - AppSpacing.md) / 2
                        : constraints.maxWidth;
                    final cards = <Widget>[
                      _StatCard(
                        label: AppStrings.totalBooks,
                        value: '${books.allBooks.length}',
                        icon: Icons.menu_book_rounded,
                      ),
                      _StatCard(
                        label: AppStrings.totalUsers,
                        value: '${admin.users.length}',
                        icon: Icons.people_alt_outlined,
                      ),
                      _StatCard(
                        label: AppStrings.totalOrders,
                        value: '${admin.orders.length}',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _StatCard(
                        label: AppStrings.totalRevenue,
                        value: AppUtils.formatPrice(revenue),
                        icon: Icons.payments_outlined,
                        isPrice: true,
                      ),
                      _StatCard(
                        label: AppStrings.lowRatedBooks,
                        value: '$lowRated',
                        icon: Icons.star_outline_rounded,
                      ),
                      for (final status in OrderStatus.values)
                        _StatCard(
                          label: status.label,
                          value: '${statusCounts[status]}',
                          icon: Icons.local_shipping_outlined,
                        ),
                    ];
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: cards
                          .map(
                            (card) => SizedBox(width: cardWidth, child: card),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: AppStrings.recentOrders,
                  child: recent.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text(AppStrings.noRecentOrders),
                        )
                      : Column(
                          children: recent
                              .map((order) => _RecentOrderRow(order: order))
                              .toList(growable: false),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: AppStrings.topBooks,
                  child: popular.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text(AppStrings.noPopularBooks),
                        )
                      : Column(
                          children: popular
                              .take(5)
                              .map(
                                (book) => ListTile(
                                  leading: AdminBookThumbnail(
                                    url: book.coverUrl,
                                  ),
                                  title: Text(
                                    book.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(book.author),
                                  trailing: Text(
                                    '${AppStrings.popularity}: ${book.popularity}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isPrice = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.titleLarge?.copyWith(
      color: AppColors.onDarkAccent,
    );
    final valueStyle = isPrice
        ? AppUtils.priceTextStyle(baseStyle: baseStyle)
        : baseStyle;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: MidnightGradients.forest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onDarkAccent),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        child,
      ],
    ),
  );
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final customer = context.select<AdminProvider, String>((admin) {
      final user = admin.userById(order.userId);
      return user == null || user.name.isEmpty
          ? user?.email ?? order.userId
          : user.name;
    });
    return ListTile(
      title: Text('${AppStrings.orderShortIdLabel} #${_shortId(order.id)}'),
      subtitle: Text(
        '$customer · ${DateFormat.yMMMd().format(order.createdAt)}',
      ),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Text(
            AppUtils.formatPrice(order.totalPrice),
            style: AppUtils.priceTextStyle(),
          ),
          AdminStatusChip(status: order.status),
        ],
      ),
      onTap: () => context.pushNamed(
        AppRoutes.adminOrderDetailsName,
        pathParameters: <String, String>{'id': order.id},
      ),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}
