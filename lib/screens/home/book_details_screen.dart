import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/book_service.dart';
import '../../widgets/design_system.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/reviews_section.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({required this.bookId, super.key});

  final String bookId;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Future<Book?> _bookFuture;

  @override
  void initState() {
    super.initState();
    _bookFuture = context.read<BookProvider>().getBookById(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book?>(
      future: _bookFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.detailsTitle)),
            body: const LoadingIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.detailsTitle)),
            body: ErrorView(
              title: AppStrings.bookLoadFailed,
              message: BookService.friendlyMessage(snapshot.error!),
              onRetry:
                  () => setState(() {
                    _bookFuture = context.read<BookProvider>().getBookById(
                      widget.bookId,
                    );
                  }),
            ),
          );
        }
        final book =
            context.watch<BookProvider>().findBookById(widget.bookId) ??
            snapshot.data;
        if (book == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.detailsTitle)),
            body: const EmptyState(
              icon: Icons.menu_book_rounded,
              title: AppStrings.bookNotFound,
              message: AppStrings.bookNotFound,
            ),
          );
        }
        return _BookDetailsPage(book: book);
      },
    );
  }
}

class _BookDetailsPage extends StatefulWidget {
  const _BookDetailsPage({required this.book});

  final Book book;

  @override
  State<_BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<_BookDetailsPage> {
  int _quantity = 1;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final book = widget.book;
    final saved = wishlist.isInWishlist(book.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 372,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: AppColors.onDarkAccent,
            surfaceTintColor: Colors.transparent,
            title: Text(
              AppStrings.detailsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _SliverCoverBackground(book: book),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _bookInformation(context, theme, book, saved: saved),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PurchaseBar(
        book: book,
        quantity: _quantity,
        isAdding: _isAdding,
        isLoggedIn: auth.isLoggedIn,
        inCart: cart.contains(book.id),
        cartQuantity: cart.quantityFor(book.id),
        onQuantityChanged: (value) => setState(() => _quantity = value),
        onAddToCart: () => _addToCart(context, auth, cart),
      ),
    );
  }

  Widget _bookInformation(
    BuildContext context,
    ThemeData theme,
    Book book, {
    required bool saved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.isBestseller)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: StatusChip(
              label: AppStrings.bestsellers,
              color: theme.colorScheme.secondary,
            ),
          ),
        Text(
          book.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text('${AppStrings.byLabel} ', style: theme.textTheme.bodyLarge),
            TextButton(
              onPressed:
                  () => context.pushNamed(
                    AppRoutes.categoryName,
                    queryParameters: <String, String>{
                      AppRoutes.categoryQueryType: AppRoutes.categoryTypeAuthor,
                      AppRoutes.categoryQueryValue: book.author,
                    },
                  ),
              child: Text(book.author),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ActionChip(
          label: Text(book.genre),
          onPressed:
              () => context.pushNamed(
                AppRoutes.categoryName,
                queryParameters: <String, String>{
                  AppRoutes.categoryQueryType: AppRoutes.categoryTypeGenre,
                  AppRoutes.categoryQueryValue: book.genre,
                },
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RatingSummary(book: book),
        if (book.releaseDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            DateFormat.yMMMMd().format(book.releaseDate!),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.bookDescription,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ExpandableDescription(description: book.description),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _toggleWishlist(context),
            icon: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            label: Text(
              saved ? AppStrings.wishlistRemove : AppStrings.addToWishlist,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ReviewsSection(book: book),
      ],
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    AuthProvider auth,
    CartProvider cart,
  ) async {
    if (!auth.isLoggedIn) {
      context.goNamed(AppRoutes.loginName);
      return;
    }
    setState(() => _isAdding = true);
    try {
      await cart.addToCart(widget.book, quantity: _quantity);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.addedToCartMessage),
          action: SnackBarAction(
            label: AppStrings.viewCart,
            onPressed: () {
              if (context.mounted) context.goNamed(AppRoutes.cartName);
            },
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
              fallback: AppStrings.cartOperationFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleWishlist(BuildContext context) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.goNamed(AppRoutes.loginName);
      return;
    }
    final wishlist = context.read<WishlistProvider>();
    final wasSaved = wishlist.isInWishlist(widget.book.id);
    try {
      await wishlist.toggleWishlist(widget.book.id);
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

class _SliverCoverBackground extends StatelessWidget {
  const _SliverCoverBackground({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (book.coverUrl.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Transform.scale(
                scale: 1.16,
                child: CachedNetworkImage(
                  imageUrl: book.coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(gradient: MidnightGradients.night),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .62),
                Colors.black.withValues(alpha: .18),
                theme.colorScheme.scrim.withValues(alpha: .70),
              ],
              stops: const <double>[0, .48, 1],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SizedBox(
              width: 164,
              height: 236,
              child: _BookCover(url: book.coverUrl, bookId: book.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.url, required this.bookId});

  final String url;
  final String bookId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: .30),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Hero(
          tag: 'book-cover-$bookId',
          child:
              url.isEmpty
                  ? _coverFallback(theme)
                  : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                    errorWidget: (context, url, error) => _coverFallback(theme),
                  ),
        ),
      ),
    );
  }

  Widget _coverFallback(ThemeData theme) => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.broken_image_outlined,
      size: 64,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            book.avgRating.toStringAsFixed(1),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: List<Widget>.generate(5, (index) {
                      final starValue = index + 1;
                      final icon =
                          book.avgRating >= starValue
                              ? Icons.star_rounded
                              : book.avgRating >= starValue - .5
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded;
                      return Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.tertiary,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.reviewCountFormat(book.ratingCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.description});

  final String description;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration:
              disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Text(
            widget.description,
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? AppStrings.readLess : AppStrings.readMore),
        ),
      ],
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.book,
    required this.quantity,
    required this.isAdding,
    required this.isLoggedIn,
    required this.inCart,
    required this.cartQuantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final Book book;
  final int quantity;
  final bool isAdding;
  final bool isLoggedIn;
  final bool inCart;
  final int cartQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: .10),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppUtils.formatPrice(book.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppUtils.priceTextStyle(
                          baseStyle: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (inCart)
                        Text(
                          '${AppStrings.inYourCart}: $cartQuantity',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IgnorePointer(
                  ignoring: !isLoggedIn || isAdding,
                  child: Opacity(
                    opacity: isLoggedIn && !isAdding ? 1 : .55,
                    child: QuantityStepper(
                      value: quantity,
                      onChanged: onQuantityChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AddToCartMotionButton(
              label: inCart ? AppStrings.inYourCart : AppStrings.addToCart,
              isLoading: isAdding,
              onPressed: isAdding ? null : onAddToCart,
            ),
          ],
        ),
      ),
    );
  }
}
