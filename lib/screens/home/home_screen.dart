import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/genre_style.dart';
import '../../models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/design_system.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/staggered_entrance.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _playedItems = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookProvider>().loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<BookProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final displayName = auth.currentUser?.name.trim().split(' ').first;
    final featuredBooks = <Book>[];
    final featuredIds = <String>{};
    for (final book in <Book>[...catalog.bestsellers, ...catalog.newArrivals]) {
      if (featuredIds.add(book.id)) featuredBooks.add(book);
      if (featuredBooks.length == 5) break;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () => context.read<BookProvider>().refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.welcomeBack}${displayName == null || displayName.isEmpty ? '' : ', $displayName'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              AppStrings.homeSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Semantics(
                        label: AppStrings.savedReads,
                        button: true,
                        child: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: IconButton(
                            tooltip: AppStrings.wishlist,
                            onPressed:
                                () => context.pushNamed(AppRoutes.wishlistName),
                            icon: const Icon(Icons.favorite_border_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    onTap: () => context.goNamed(AppRoutes.searchName),
                    child: GlassBar(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                AppStrings.searchHint,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.tune_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (catalog.isLoading && !catalog.hasLoaded)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: HomeSkeleton(),
                )
              else if (catalog.errorMessage != null && catalog.allBooks.isEmpty)
                SliverFillRemaining(
                  child: ErrorView(
                    message: catalog.errorMessage,
                    onRetry: () => context.read<BookProvider>().refresh(),
                  ),
                )
              else if (catalog.allBooks.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.auto_stories_rounded,
                    title: AppStrings.noBooks,
                    message: AppStrings.noBooksAvailable,
                  ),
                )
              else ...[
                if (catalog.errorMessage != null)
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: MaterialBanner(
                        content: Text(catalog.errorMessage!),
                        actions: [
                          TextButton(
                            onPressed:
                                () => context.read<BookProvider>().refresh(),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (featuredBooks.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _FeatureCarousel(
                        books: featuredBooks,
                        onOpenBook: (book) => _openBook(context, book),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _BookSection(
                      title: AppStrings.bestsellers,
                      books: catalog.bestsellers,
                      onSeeAll: () => context.goNamed(AppRoutes.searchName),
                      showRank: true,
                      playedItems: _playedItems,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: _BookSection(
                      title: AppStrings.newArrivals,
                      books: catalog.newArrivals,
                      showNewArrivalRibbon: true,
                      playedItems: _playedItems,
                    ),
                  ),
                ),
                if (catalog.genres.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: _GenreSection(
                        genres: catalog.genres,
                        playedItems: _playedItems,
                        onSelect:
                            (genre) => _openCategory(
                              context,
                              AppRoutes.categoryTypeGenre,
                              genre,
                            ),
                      ),
                    ),
                  ),
                if (catalog.authors.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.lg,
                      0,
                      AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _AuthorSection(
                        authors: catalog.authors,
                        playedItems: _playedItems,
                        onSelect:
                            (author) => _openCategory(
                              context,
                              AppRoutes.categoryTypeAuthor,
                              author,
                            ),
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, String type, String value) {
    context.pushNamed(
      AppRoutes.categoryName,
      queryParameters: <String, String>{
        AppRoutes.categoryQueryType: type,
        AppRoutes.categoryQueryValue: value,
      },
    );
  }

  void _openBook(BuildContext context, Book book) {
    context.pushNamed(
      AppRoutes.bookDetailsName,
      pathParameters: <String, String>{'id': book.id},
    );
  }
}

class _FeatureCarousel extends StatefulWidget {
  const _FeatureCarousel({required this.books, required this.onOpenBook});

  final List<Book> books;
  final ValueChanged<Book> onOpenBook;

  @override
  State<_FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<_FeatureCarousel> {
  static const Duration _slideInterval = Duration(seconds: 5);
  static const Duration _slideDuration = Duration(milliseconds: 550);

  final PageController _pageController = PageController();
  Timer? _timer;
  int _activeIndex = 0;
  bool _pointerIsDown = false;
  bool _animationsDisabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (_animationsDisabled != disableAnimations) {
      _animationsDisabled = disableAnimations;
      _restartTimer();
    } else if (_timer == null) {
      _restartTimer();
    }
  }

  @override
  void didUpdateWidget(covariant _FeatureCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final booksChanged =
        oldWidget.books.length != widget.books.length ||
        List<bool>.generate(
          oldWidget.books.length,
          (index) => oldWidget.books[index].id != widget.books[index].id,
        ).contains(true);
    if (!booksChanged) return;
    _activeIndex = 0;
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_animationsDisabled || _pointerIsDown || widget.books.length < 2) {
      return;
    }
    _timer = Timer.periodic(_slideInterval, (_) {
      if (!mounted || _pointerIsDown || _animationsDisabled) return;
      final nextIndex = (_activeIndex + 1) % widget.books.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextIndex,
          duration: _slideDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _pauseWhileInteracting(PointerEvent _) {
    _pointerIsDown = true;
    _timer?.cancel();
    _timer = null;
  }

  void _resumeAfterInteraction(PointerEvent _) {
    _pointerIsDown = false;
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: AppStrings.featuredBooks,
      value: AppStrings.featuredPageFormat(
        _activeIndex + 1,
        widget.books.length,
      ),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _pauseWhileInteracting,
        onPointerUp: _resumeAfterInteraction,
        onPointerCancel: _resumeAfterInteraction,
        child: Column(
          children: [
            SizedBox(
              height: 232,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.books.length,
                onPageChanged: (index) {
                  setState(() => _activeIndex = index);
                  _restartTimer();
                },
                itemBuilder:
                    (context, index) => _FeatureHero(
                      book: widget.books[index],
                      onTap: () => widget.onOpenBook(widget.books[index]),
                    ),
              ),
            ),
            if (widget.books.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              AnimatedSmoothIndicator(
                activeIndex: _activeIndex,
                count: widget.books.length,
                duration:
                    _animationsDisabled
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                onDotClicked: (index) {
                  _pageController.animateToPage(
                    index,
                    duration:
                        _animationsDisabled ? Duration.zero : _slideDuration,
                    curve: Curves.easeInOutCubic,
                  );
                },
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 2.5,
                  spacing: AppSpacing.sm,
                  activeDotColor: theme.colorScheme.primary,
                  dotColor: theme.colorScheme.outlineVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureHero extends StatelessWidget {
  const _FeatureHero({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrim = theme.colorScheme.scrim;
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 224,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: MidnightGradients.night,
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (book.coverUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: book.coverUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scrim.withValues(alpha: .92),
                    scrim.withValues(alpha: .60),
                    scrim.withValues(alpha: .13),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StatusChip(
                    label: AppStrings.featuredBook,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.onDarkAccent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onDarkAccent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          AppStrings.discoverBook,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.secondary,
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
}

class _BookSection extends StatelessWidget {
  const _BookSection({
    required this.title,
    required this.books,
    this.onSeeAll,
    this.showRank = false,
    this.showNewArrivalRibbon = false,
    required this.playedItems,
  });

  final String title;
  final List<Book> books;
  final VoidCallback? onSeeAll;
  final bool showRank;
  final bool showNewArrivalRibbon;
  final Set<String> playedItems;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(
            title: title,
            actionLabel: onSeeAll == null ? null : AppStrings.seeAll,
            onAction: onSeeAll,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 355,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder:
                (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final book = books[index];
              return StaggeredEntrance(
                key: ValueKey<String>('home-$title-${book.id}'),
                itemId: 'home-$title-${book.id}',
                index: index,
                playedItemIds: playedItems,
                child: SizedBox(
                  width: 168,
                  child: BookCard(
                    book: book,
                    rank: showRank ? index + 1 : null,
                    showNewArrivalRibbon: showNewArrivalRibbon,
                    onTap: () => context.pushNamed(
                      AppRoutes.bookDetailsName,
                      pathParameters: <String, String>{'id': book.id},
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GenreSection extends StatelessWidget {
  const _GenreSection({
    required this.genres,
    required this.onSelect,
    required this.playedItems,
  });

  final List<String> genres;
  final ValueChanged<String> onSelect;
  final Set<String> playedItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(title: AppStrings.genres),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => StaggeredEntrance(
              key: ValueKey<String>('home-genre-${genres[index]}'),
              itemId: 'home-genre-${genres[index]}',
              index: index,
              playedItemIds: playedItems,
              child: InkWell(
                  onTap: () => onSelect(genres[index]),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Container(
                    width: 138,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: GenreStyle.forName(genres[index]).gradient,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          GenreStyle.forName(genres[index]).icon,
                          color: AppColors.onDarkAccent,
                        ),
                        Text(
                          genres[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onDarkAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthorSection extends StatelessWidget {
  const _AuthorSection({
    required this.authors,
    required this.onSelect,
    required this.playedItems,
  });

  final List<String> authors;
  final ValueChanged<String> onSelect;
  final Set<String> playedItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SectionHeader(title: AppStrings.browseAuthors),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: authors.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final author = authors[index];
              final initials =
                  author.trim().isEmpty
                      ? '?'
                      : author
                          .trim()
                          .split(RegExp(r'\s+'))
                          .take(2)
                          .map((part) => part[0].toUpperCase())
                          .join();
              return StaggeredEntrance(
                key: ValueKey<String>('home-author-$author'),
                itemId: 'home-author-$author',
                index: index,
                playedItemIds: playedItems,
                child: InkWell(
                onTap: () => onSelect(author),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: GenreStyle.avatarGradientFor(author),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: .16,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.onDarkAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
