import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeletons.dart';
import '../../widgets/staggered_entrance.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  final Set<String> _playedItems = <String>{};

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<BookProvider>().query,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookProvider>().loadCatalog();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<BookProvider>().setQuery(value);
    });
  }

  void _clearAll(BookProvider provider) {
    _debounce?.cancel();
    _controller.clear();
    provider.clearFilters();
  }

  Future<void> _openFilters(BookProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final books = provider.filteredBooks;
    final theme = Theme.of(context);
    final activeCount =
        (provider.selectedGenre == null ? 0 : 1) +
        (provider.selectedAuthor == null ? 0 : 1) +
        (provider.priceRange == null ? 0 : 1);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: AppStrings.searchHint,
                        prefixIcon: Icon(Icons.search_rounded),
                        suffixIcon: Icon(Icons.manage_search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Badge(
                    isLabelVisible: activeCount > 0,
                    label: Text('$activeCount'),
                    child: IconButton.filledTonal(
                      tooltip: AppStrings.filters,
                      onPressed: () => _openFilters(provider),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
              if (provider.errorMessage != null && provider.allBooks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    provider.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (provider.selectedGenre != null ||
                  provider.selectedAuthor != null ||
                  provider.priceRange != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (provider.selectedGenre != null)
                      InputChip(
                        label: Text(provider.selectedGenre!),
                        onDeleted: () => provider.setGenre(null),
                      ),
                    if (provider.selectedAuthor != null)
                      InputChip(
                        label: Text(provider.selectedAuthor!),
                        onDeleted: () => provider.setAuthor(null),
                      ),
                    if (provider.priceRange != null)
                      InputChip(
                        label: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: AppUtils.formatPrice(
                                  provider.priceRange!.start,
                                ),
                                style: AppUtils.priceTextStyle(),
                              ),
                              const TextSpan(text: ' – '),
                              TextSpan(
                                text: AppUtils.formatPrice(
                                  provider.priceRange!.end,
                                ),
                                style: AppUtils.priceTextStyle(),
                              ),
                            ],
                          ),
                        ),
                        onDeleted: () => provider.setPriceRange(null),
                      ),
                    TextButton(
                      onPressed: () => _clearAll(provider),
                      child: const Text(AppStrings.clearFilters),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${books.length} ${AppStrings.results}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildResults(provider, books)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BookProvider provider, List<Book> books) {
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
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
          );
        },
      );
    }
    if (provider.errorMessage != null && provider.allBooks.isEmpty) {
      return ErrorView(
        message: provider.errorMessage,
        onRetry: () => provider.refresh(),
      );
    }
    if (books.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: AppStrings.noBooksFound,
        message: AppStrings.noBooksFoundMessage,
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
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.57,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return StaggeredEntrance(
              key: ValueKey<String>('search-${book.id}'),
              itemId: 'search-${book.id}',
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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.provider});

  final BookProvider provider;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _genre;
  late String? _author;
  late BookSortOption _sort;
  late RangeValues _range;
  late double _minimum;
  late double _maximum;

  @override
  void initState() {
    super.initState();
    final prices = widget.provider.allBooks.map((book) => book.price).toList();
    _minimum = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    final double actualMax =
        prices.isEmpty ? 100.0 : prices.reduce((a, b) => a > b ? a : b);
    _maximum = actualMax > _minimum ? actualMax : _minimum + 1.0;
    _genre = widget.provider.selectedGenre;
    _author = widget.provider.selectedAuthor;
    _sort = widget.provider.sortOption;
    final savedRange = widget.provider.priceRange;
    _range =
        savedRange == null
            ? RangeValues(_minimum, _maximum)
            : RangeValues(
              savedRange.start.clamp(_minimum, _maximum).toDouble(),
              savedRange.end.clamp(_minimum, _maximum).toDouble(),
            );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.filters,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.closeLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  AppStrings.filterGenre,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text(AppStrings.allGenres),
                      selected: _genre == null,
                      onSelected: (_) => setState(() => _genre = null),
                    ),
                    ...widget.provider.genres.map(
                      (genre) => ChoiceChip(
                        label: Text(genre),
                        selected: _genre == genre,
                        onSelected:
                            (_) => setState(
                              () => _genre = _genre == genre ? null : genre,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.filterAuthor,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text(AppStrings.allAuthors),
                      selected: _author == null,
                      onSelected: (_) => setState(() => _author = null),
                    ),
                    ...widget.provider.authors.map(
                      (author) => ChoiceChip(
                        label: Text(author),
                        selected: _author == author,
                        onSelected:
                            (_) => setState(
                              () => _author = _author == author ? null : author,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(AppStrings.priceRange, style: theme.textTheme.titleMedium),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    valueIndicatorTextStyle: AppUtils.priceTextStyle(
                      baseStyle:
                          SliderTheme.of(context).valueIndicatorTextStyle,
                    ),
                  ),
                  child: RangeSlider(
                    min: _minimum,
                    max: _maximum,
                    divisions: 100,
                    values: _range,
                    labels: RangeLabels(
                      AppUtils.formatPrice(_range.start),
                      AppUtils.formatPrice(_range.end),
                    ),
                    onChanged: (value) => setState(() => _range = value),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${AppStrings.minPrice}: '),
                          TextSpan(
                            text: AppUtils.formatPrice(_range.start),
                            style: AppUtils.priceTextStyle(),
                          ),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${AppStrings.maxPrice}: '),
                          TextSpan(
                            text: AppUtils.formatPrice(_range.end),
                            style: AppUtils.priceTextStyle(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<BookSortOption>(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: AppStrings.sortBy,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: BookSortOption.priceLowToHigh,
                      child: Text(AppStrings.priceLowToHigh),
                    ),
                    DropdownMenuItem(
                      value: BookSortOption.priceHighToLow,
                      child: Text(AppStrings.priceHighToLow),
                    ),
                    DropdownMenuItem(
                      value: BookSortOption.popularity,
                      child: Text(AppStrings.popularitySort),
                    ),
                    DropdownMenuItem(
                      value: BookSortOption.newestFirst,
                      child: Text(AppStrings.newestFirst),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.provider
                    ..setGenre(_genre)
                    ..setAuthor(_author)
                    ..setSort(_sort)
                    ..setPriceRange(
                      _range.start <= _minimum && _range.end >= _maximum
                          ? null
                          : _range,
                    );
                  Navigator.of(context).pop();
                },
                child: const Text(AppStrings.applyFilters),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
