import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../models/cart_item.dart';
import '../../providers/book_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/book_thumb.dart';
import '../../widgets/design_system.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/staggered_entrance.dart';
import '../../widgets/quantity_stepper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _playedItems = <String>{};

  @override
  void initState() {
    super.initState();
    final books = context.read<BookProvider>();
    if (!books.hasLoaded) unawaited(books.loadCatalog());
  }

  @override
  Widget build(BuildContext context) => Consumer2<CartProvider, BookProvider>(
    builder: (context, cart, books, _) {
      final isBusy = (cart.isLoading && cart.items.isEmpty) ||
          (books.isLoading && !books.hasLoaded);
      final isEmpty = cart.items.isEmpty;
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.cart)),
        body: isBusy
            ? const CartListSkeleton()
            : cart.errorMessage != null && isEmpty
                ? ErrorView(
                    title: AppStrings.errorTitle,
                    message: cart.errorMessage!,
                    onRetry: cart.retry,
                  )
                : books.errorMessage != null && !books.hasLoaded
                    ? ErrorView(
                        title: AppStrings.catalogLoadFailed,
                        message: books.errorMessage!,
                        onRetry: () => unawaited(books.refresh()),
                      )
                    : isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                const Expanded(
                                  child: EmptyState(
                                    icon: Icons.shopping_bag_outlined,
                                    accentIcon: Icons.menu_book_rounded,
                                    title: AppStrings.cartEmptyTitle,
                                    message: AppStrings.cartEmptyMessage,
                                  ),
                                ),
                                GradientButton(
                                  label: AppStrings.browseBooks,
                                  icon: Icons.menu_book_rounded,
                                  onPressed: () => context.goNamed(AppRoutes.homeName),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final list = _CartItemsList(
                                items: cart.items,
                                includeSummary: constraints.maxWidth < 820,
                                cart: cart,
                                playedItems: _playedItems,
                              );
                              if (constraints.maxWidth >= 820) {
                                return Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 1180),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: list),
                                          const SizedBox(width: AppSpacing.lg),
                                          SizedBox(
                                            width: 340,
                                            child: _OrderSummary(cart: cart),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return list;
                            },
                          ),
        bottomNavigationBar: isEmpty || isBusy || cart.errorMessage != null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: GlassBar(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: GradientButton(
                        label: AppStrings.checkoutTotal(AppUtils.formatPrice(cart.total)),
                        icon: Icons.arrow_forward_rounded,
                        onPressed: cart.items.any((item) => !item.unavailable)
                            ? () => context.pushNamed(AppRoutes.checkoutName)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

class _CartItemsList extends StatelessWidget {
  const _CartItemsList({
    required this.items,
    required this.includeSummary,
    required this.cart,
    required this.playedItems,
  });

  final List<CartItem> items;
  final bool includeSummary;
  final CartProvider cart;
  final Set<String> playedItems;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.md),
    itemCount: items.length + (includeSummary ? 1 : 0),
    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) {
      if (index == items.length) return _OrderSummary(cart: cart);
      final item = items[index];
      return StaggeredEntrance(
        key: ValueKey<String>('cart-${item.bookId}'),
        itemId: 'cart-${item.bookId}',
        index: index,
        playedItemIds: playedItems,
        child: _CartItemTile(item: item),
      );
    },
  );
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();
    return Dismissible(
      key: ValueKey<String>(item.bookId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: MidnightGradients.alert,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _remove(context, cart, item),
      child: Card(
        elevation: 1.2,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookThumb(url: item.coverUrl, width: 72, height: 98),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.author.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.unavailable
                          ? AppStrings.unavailableBook
                          : AppUtils.formatPrice(item.price),
                      style: item.unavailable
                          ? theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            )
                          : AppUtils.priceTextStyle(
                              baseStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        QuantityStepper(
                          value: item.quantity,
                          onChanged: (quantity) => _update(
                            context,
                            cart,
                            item,
                            quantity,
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.remove,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _remove(context, cart, item),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        item.unavailable
                            ? AppStrings.unavailableLineTotal
                            : AppUtils.formatPrice(item.price * item.quantity),
                        style: item.unavailable
                            ? theme.textTheme.titleSmall
                            : AppUtils.priceTextStyle(
                                baseStyle: theme.textTheme.titleSmall,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _update(
    BuildContext context,
    CartProvider cart,
    CartItem item,
    int quantity,
  ) {
    unawaited(
      cart.updateQuantity(item.bookId, quantity).catchError((Object error) {
        if (context.mounted) {
          _showMessage(
            context,
            ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
          );
        }
      }),
    );
  }

  static void _remove(BuildContext context, CartProvider cart, CartItem item) {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      cart.removeItem(item.bookId).catchError((Object error) {
        if (messenger.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
              ),
            ),
          );
        }
      }),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(AppStrings.cartRemovedMessage),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () {
              unawaited(
                cart.restoreItem(item.bookId, item.quantity).catchError((Object error) {
                  if (messenger.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ErrorHandler.message(
                            error,
                            fallback: AppStrings.cartOperationFailed,
                          ),
                        ),
                      ),
                    );
                  }
                }),
              );
            },
          ),
        ),
      );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.orderSummary, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _SummaryLine(label: AppStrings.itemCount, value: '${cart.itemCount}'),
            const SizedBox(height: AppSpacing.sm),
            _SummaryLine(
              label: AppStrings.subtotal,
              value: AppUtils.formatPrice(cart.subtotal),
              isPrice: true,
            ),
            const Divider(height: AppSpacing.lg),
            _SummaryLine(
              label: AppStrings.total,
              value: AppUtils.formatPrice(cart.total),
              emphasize: true,
              isPrice: true,
            ),
            if (cart.items.any((item) => item.unavailable)) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.unavailableItemsExcluded,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isPrice = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool isPrice;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          )
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isPrice ? AppUtils.priceTextStyle(baseStyle: style) : style,
          ),
        ),
      ],
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
