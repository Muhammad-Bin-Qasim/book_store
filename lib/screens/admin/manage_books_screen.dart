import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../models/book.dart';
import '../../providers/admin_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_thumb.dart';
import '../../widgets/design_system.dart';
import 'admin_scaffold.dart';
import 'admin_ui.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  String _search = '';
  String? _genre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookProvider>().loadCatalog();
    });
  }

  Future<void> _refresh() async {
    try {
      await context.read<BookProvider>().refresh();
    } catch (_) {
      // The provider exposes the catalog error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: AppStrings.manageBooks,
      selectedIndex: 1,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: MidnightGradients.forest,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: .22),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => context.pushNamed(AppRoutes.adminBookCreateName),
          icon: const Icon(Icons.add_rounded),
          label: const Text(AppStrings.addBook),
        ),
      ),
      child: Consumer<BookProvider>(
        builder: (context, provider, _) {
          final filtered =
              provider.allBooks.where((book) {
                  final query = _search.trim().toLowerCase();
                  final matchesSearch =
                      query.isEmpty ||
                      book.title.toLowerCase().contains(query) ||
                      book.author.toLowerCase().contains(query);
                  final matchesGenre = _genre == null || book.genre == _genre;
                  return matchesSearch && matchesGenre;
                }).toList()
                ..sort(
                  (a, b) =>
                      a.title.toLowerCase().compareTo(b.title.toLowerCase()),
                );
          if (provider.errorMessage != null && !provider.hasLoaded) {
            return AdminErrorView(
              message: provider.errorMessage!,
              onRetry: _refresh,
            );
          }
          if (provider.isLoading && !provider.hasLoaded) {
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
                          width: wide ? 360 : constraints.maxWidth,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: AppStrings.searchBooks,
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged:
                                (value) => setState(() => _search = value),
                          ),
                        ),
                        SizedBox(
                          width: wide ? 220 : constraints.maxWidth,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _genre,
                            decoration: const InputDecoration(
                              labelText: AppStrings.filterBooksByGenre,
                            ),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(AppStrings.allBooks),
                              ),
                              ...provider.genres.map(
                                (genre) => DropdownMenuItem<String?>(
                                  value: genre,
                                  child: Text(genre),
                                ),
                              ),
                            ],
                            onChanged:
                                (value) => setState(() => _genre = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (filtered.isEmpty)
                      SizedBox(
                        height: 220,
                        child: Center(child: Text(AppStrings.noManagedBooks)),
                      )
                    else if (wide)
                      _BooksTable(
                        books: filtered,
                        onEdit: _edit,
                        onDelete: _delete,
                      )
                    else
                      ...filtered.map(
                        (book) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Dismissible(
                            key: ValueKey<String>(book.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: MidnightGradients.alert,
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                            ),
                            confirmDismiss: (_) => _confirmDelete(book),
                            onDismissed: (_) => _delete(book, confirm: false),
                            child: Card(
                              elevation: 1.2,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Row(
                                  children: [
                                    BookThumb(url: book.coverUrl, width: 56, height: 74),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            '${book.author} · ${book.genre}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Wrap(
                                            spacing: AppSpacing.xs,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(AppUtils.formatPrice(book.price), style: AppUtils.priceTextStyle()),
                                              Text('· ${_rating(book)}', style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: AppStrings.editBook,
                                      onSelected: (action) => action == 'edit' ? _edit(book) : _delete(book),
                                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem(value: 'edit', child: Text(AppStrings.editBook)),
                                        const PopupMenuItem(value: 'delete', child: Text(AppStrings.deleteBook)),
                                      ],
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
              },
            ),
          );
        },
      ),
    );
  }

  void _edit(Book book) => context.pushNamed(
    AppRoutes.adminBookEditName,
    pathParameters: <String, String>{'id': book.id},
  );

  Future<bool> _confirmDelete(Book book) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(AppStrings.deleteBook),
          content: const Text(AppStrings.deleteBookConfirmation),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.deleteBook),
            ),
          ],
        ),
      ) ?? false;

  Future<void> _delete(Book book, {bool confirm = true}) async {
    if (confirm && !(await _confirmDelete(book))) return;
    if (!mounted) return;
    final admin = context.read<AdminProvider>();
    final books = context.read<BookProvider>();
    try {
      await admin.deleteBook(book.id);
      if (!mounted) return;
      await books.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.bookDeleted)),
      );
    } catch (error) {
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(error, fallback: AppStrings.adminOperationFailed),
          ),
        ),
      );
    }
  }

  static String _rating(Book book) =>
      '${book.avgRating.toStringAsFixed(1)} (${book.ratingCount})';
}

class _BooksTable extends StatelessWidget {
  const _BooksTable({
    required this.books,
    required this.onEdit,
    required this.onDelete,
  });
  final List<Book> books;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1.2,
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text(AppStrings.coverImage)),
          DataColumn(label: Text(AppStrings.bookTitle)),
          DataColumn(label: Text(AppStrings.bookAuthor)),
          DataColumn(label: Text(AppStrings.bookGenre)),
          DataColumn(label: Text(AppStrings.bookPrice)),
          DataColumn(label: Text(AppStrings.bestseller)),
          DataColumn(label: Text(AppStrings.ratingLabel)),
          DataColumn(label: Text(AppStrings.editBook)),
        ],
        rows: books
            .map(
              (book) => DataRow(
                cells: <DataCell>[
                  DataCell(BookThumb(url: book.coverUrl, width: 44, height: 58)),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(book.author)),
                  DataCell(Text(book.genre)),
                  DataCell(
                    Text(
                      AppUtils.formatPrice(book.price),
                      style: AppUtils.priceTextStyle(),
                    ),
                  ),
                  DataCell(
                    Icon(
                      book.isBestseller
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                    ),
                  ),
                  DataCell(
                    Text(
                      '${book.avgRating.toStringAsFixed(1)} (${book.ratingCount})',
                    ),
                  ),
                  DataCell(
                    Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: AppStrings.editBook,
                          onPressed: () => onEdit(book),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: AppStrings.deleteBook,
                          onPressed: () => onDelete(book),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    ),
  );
}
