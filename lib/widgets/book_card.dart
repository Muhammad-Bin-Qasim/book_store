import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_routes.dart';
import '../core/app_utils.dart';
import '../core/utils/error_handler.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import 'design_system.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    this.onTap,
    this.rank,
    this.showNewArrivalRibbon = false,
    super.key,
  });

  final Book book;
  final VoidCallback? onTap;
  final int? rank;
  final bool showNewArrivalRibbon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = context.watch<WishlistProvider>().isInWishlist(book.id);
    return PressScale(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'book-cover-${book.id}',
                    child:
                        book.coverUrl.isEmpty
                            ? ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            )
                            : CachedNetworkImage(
                              imageUrl: book.coverUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => ColoredBox(
                                    color:
                                        theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  ),
                              errorWidget:
                                  (context, url, error) => ColoredBox(
                                    color:
                                        theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                            ),
                  ),
                  if (rank != null)
                    Positioned(
                      left: AppSpacing.xs,
                      bottom: 0,
                      child: Semantics(
                        label: AppStrings.bookRankFormat(rank!),
                        excludeSemantics: true,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 88,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            foreground:
                                Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..color = AppColors.onDarkAccent.withValues(
                                    alpha: .9,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  if (book.isBestseller)
                    Positioned(
                      top:
                          showNewArrivalRibbon
                              ? AppSpacing.xl + AppSpacing.xs
                              : AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          gradient: MidnightGradients.ember,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          AppStrings.bestsellers,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (showNewArrivalRibbon)
                    Positioned(
                      top: AppSpacing.md,
                      left: -AppSpacing.xl,
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: Container(
                          width: 112,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: MidnightGradients.indigo,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(
                                  alpha: .24,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            AppStrings.newLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.onDarkAccent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: .92),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedHeart(
                        selected: saved,
                        tooltip:
                            saved
                                ? AppStrings.wishlistRemove
                                : AppStrings.addToWishlist,
                        onTap: () => _toggleWishlist(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
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
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        book.avgRating.toStringAsFixed(1),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            AppUtils.formatPrice(book.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppUtils.priceTextStyle(
                              baseStyle: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWishlist(BuildContext context) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.goNamed(AppRoutes.loginName);
      return;
    }
    final wishlist = context.read<WishlistProvider>();
    try {
      final wasSaved = wishlist.isInWishlist(book.id);
      await wishlist.toggleWishlist(book.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? AppStrings.wishlistRemoved : AppStrings.wishlistSaved,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(
              error,
              fallback: AppStrings.wishlistOperationFailed,
            ),
          ),
        ),
      );
    }
  }
}
