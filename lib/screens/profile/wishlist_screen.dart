import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/motion.dart';
import '../../core/utils/error_handler.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/book_thumb.dart';
import '../../widgets/design_system.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/staggered_entrance.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Set<String> _playedItems = <String>{};

  @override
  void initState() {
    super.initState();
    final books = context.read<BookProvider>();
    if (!books.hasLoaded) unawaited(books.loadCatalog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.wishlist)),
      body: Consumer2<WishlistProvider, BookProvider>(
        builder: (context, wishlist, books, _) {
          if (wishlist.isLoading || (books.isLoading && !books.hasLoaded)) {
            return const WishlistGridSkeleton();
          }
          if (wishlist.errorMessage != null && wishlist.books.isEmpty) {
            return ErrorView(
              title: AppStrings.errorTitle,
              message: wishlist.errorMessage!,
              onRetry: wishlist.retry,
            );
          }
          if (books.errorMessage != null && !books.hasLoaded) {
            return ErrorView(
              title: AppStrings.catalogLoadFailed,
              message: books.errorMessage!,
              onRetry: () => unawaited(books.refresh()),
            );
          }
          if (wishlist.books.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: EmptyState(
                icon: Icons.favorite_border_rounded,
                accentIcon: Icons.bookmark_add_outlined,
                title: AppStrings.wishlistEmptyTitle,
                message: AppStrings.wishlistEmptyMessage,
              ),
            );
          }
          final gridKey = ValueKey<String>(
            wishlist.books.map((book) => book.id).join('|'),
          );
          return LayoutBuilder(
            builder: (context, constraints) => AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.standard),
              switchInCurve: AppMotion.enterCurve,
              switchOutCurve: AppMotion.exitCurve,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .985, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: GridView.builder(
                key: gridKey,
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 760 ? 3 : 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisExtent: constraints.maxWidth < 400 ? 350 : 370,
                ),
                itemCount: wishlist.books.length,
                itemBuilder: (context, index) {
                  final book = wishlist.books[index];
                  return StaggeredEntrance(
                    key: ValueKey<String>('wishlist-${book.id}'),
                    itemId: 'wishlist-${book.id}',
                    index: index,
                    playedItemIds: _playedItems,
                    child: _WishlistBookCard(
                      key: ValueKey<String>(book.id),
                      book: book,
                      onRemove: () => _remove(context, book),
                      onMoveToCart: () => _moveToCart(context, book),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _moveToCart(BuildContext context, Book book) async {
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();
    try {
      await cart.addToCart(book);
      await wishlist.removeFromWishlist(book.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.movedToCartMessage)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(error, fallback: AppStrings.cartOperationFailed),
          ),
        ),
      );
    }
  }

  Future<void> _remove(BuildContext context, Book book) async {
    try {
      await context.read<WishlistProvider>().removeFromWishlist(book.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(error, fallback: AppStrings.wishlistOperationFailed),
          ),
        ),
      );
    }
  }
}

class _WishlistBookCard extends StatelessWidget {
  const _WishlistBookCard({
    required this.book,
    required this.onRemove,
    required this.onMoveToCart,
    super.key,
  });

  final Book book;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 154,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: InkWell(
                    onTap: () => context.pushNamed(
                      AppRoutes.bookDetailsName,
                      pathParameters: <String, String>{'id': book.id},
                    ),
                    child: BookThumb(
                      url: book.coverUrl,
                      width: double.infinity,
                      height: 154,
                      borderRadius: 0,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Material(
                    color: theme.colorScheme.surface.withValues(alpha: .92),
                    shape: const CircleBorder(),
                    child: AnimatedHeart(
                      selected: true,
                      tooltip: AppStrings.wishlistRemove,
                      onTap: onRemove,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppUtils.formatPrice(book.price),
                    style: AppUtils.priceTextStyle(
                      baseStyle: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      button: true,
                      label: AppStrings.moveToCart,
                      child: PressScale(
                        onTap: onMoveToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 18, color: theme.colorScheme.onSecondaryContainer),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  AppStrings.moveToCart,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
