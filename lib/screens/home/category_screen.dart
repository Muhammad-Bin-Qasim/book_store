import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/design_system.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/staggered_entrance.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({required this.type, required this.value, super.key});

  final String type;
  final String value;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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
    final provider = context.watch<BookProvider>();
    final isAuthor = widget.type == AppRoutes.categoryTypeAuthor;
    final books = provider.allBooks
        .where((book) {
          final candidate = isAuthor ? book.author : book.genre;
          return candidate.toLowerCase() == widget.value.toLowerCase();
        })
        .toList(growable: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.value.isEmpty ? AppStrings.category : widget.value),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: MidnightGradients.forest,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: .15),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    isAuthor ? Icons.person_outline_rounded : Icons.auto_stories_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAuthor ? AppStrings.authorCategory : AppStrings.genreCategory,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppStrings.booksMatchCount(books.length),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: .9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<BookProvider>().refresh(),
              child: _buildContent(provider, books),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BookProvider provider, List<Book> books) {
    if (provider.isLoading && !provider.hasLoaded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 5
              : constraints.maxWidth >= 700
                  ? 4
                  : 2;
          return BookGridSkeleton(
            columns: columns,
            mainAxisExtent: constraints.maxWidth < 400 ? 322 : 344,
          );
        },
      );
    }
    if (provider.errorMessage != null && provider.allBooks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: ErrorView(
              message: provider.errorMessage,
              onRetry: () => provider.refresh(),
            ),
          ),
        ],
      );
    }
    if (books.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 420,
            child: EmptyState(
              icon: Icons.library_books_outlined,
              title: AppStrings.noBooksFound,
              message: AppStrings.noCategoryBooks,
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1000
                ? 5
                : constraints.maxWidth >= 700
                ? 4
                : 2;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: constraints.maxWidth < 400 ? 322 : 344,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return StaggeredEntrance(
              key: ValueKey<String>('category-${book.id}'),
              itemId: 'category-${book.id}',
              index: index,
              playedItemIds: _playedItems,
              child: BookCard(
                book: book,
                onTap: () => context.pushNamed(
                  AppRoutes.bookDetailsName,
                  pathParameters: <String, String>{'id': book.id},
                ),
              ),
            );
          },
        );
      },
    );
  }
}
