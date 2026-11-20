import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/utils/error_handler.dart';
import '../../models/book.dart';
import '../../providers/admin_provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/design_system.dart';
import 'admin_scaffold.dart';
import 'admin_ui.dart';

class AdminBookFormScreen extends StatefulWidget {
  const AdminBookFormScreen({this.bookId, super.key});
  final String? bookId;

  @override
  State<AdminBookFormScreen> createState() => _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends State<AdminBookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _popularity = TextEditingController(text: '0');
  final _coverUrl = TextEditingController();
  DateTime? _releaseDate;
  String? _genre;
  List<String> _genres = const <String>[];
  bool _isBestseller = false;
  bool _isSaving = false;
  bool _isLoading = true;
  double? _uploadProgress;
  Uint8List? _coverBytes;
  String _coverContentType = 'image/jpeg';
  Book? _existingBook;
  String? _loadError;

  bool get _isEditing => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    _genres = context.read<BookProvider>().genres;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBook());
  }

  Future<void> _loadBook() async {
    if (!mounted) return;
    setState(() {
      _loadError = null;
      _isLoading = _isEditing;
    });
    final books = context.read<BookProvider>();
    try {
      if (!books.hasLoaded) await books.loadCatalog();
      if (!mounted) return;
      setState(() => _genres = books.genres);
      if (!_isEditing) return;
      final existing =
          books.findBookById(widget.bookId!) ??
          await books.getBookById(widget.bookId!);
      if (!mounted) return;
      if (existing == null) {
        setState(() => _loadError = AppStrings.bookNotFound);
        return;
      }
      setState(() {
        _existingBook = existing;
        _title.text = existing.title;
        _author.text = existing.author;
        _description.text = existing.description;
        _price.text = existing.price.toStringAsFixed(2);
        _popularity.text = existing.popularity.toString();
        _coverUrl.text = existing.coverUrl;
        _releaseDate = existing.releaseDate;
        _genre = existing.genre;
        _isBestseller = existing.isBestseller;
        if (!_genres.contains(existing.genre)) {
          _genres = <String>[..._genres, existing.genre];
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = ErrorHandler.message(
          error,
          fallback: AppStrings.adminOperationFailed,
        );
      });
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _description.dispose();
    _price.dispose();
    _popularity.dispose();
    _coverUrl.dispose();
    super.dispose();
  }

  Future<void> _addGenre() async {
    final controller = TextEditingController();
    final genre = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text(AppStrings.addNewGenre),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: AppStrings.newGenre),
              textCapitalization: TextCapitalization.words,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed:
                    () =>
                        Navigator.of(dialogContext).pop(controller.text.trim()),
                child: const Text(AppStrings.save),
              ),
            ],
          ),
    );
    controller.dispose();
    if (!mounted || genre == null || genre.trim().isEmpty) return;
    setState(() {
      if (!_genres.any((value) => value.toLowerCase() == genre.toLowerCase())) {
        _genres = <String>[..._genres, genre.trim()];
      }
      _genre = _genres.firstWhere(
        (value) => value.toLowerCase() == genre.toLowerCase(),
      );
    });
  }

  Future<void> _pickCover() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _coverBytes = bytes;
        _coverUrl.clear();
        _coverContentType = picked.mimeType ?? 'image/jpeg';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.storageUploadFailed)),
      );
    }
  }

  Future<void> _chooseReleaseDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 20),
    );
    if (!mounted || value == null) return;
    setState(() => _releaseDate = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final genre = _genre?.trim() ?? '';
    if (genre.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.requiredField)));
      return;
    }
    setState(() {
      _isSaving = true;
      _uploadProgress = null;
    });
    try {
      final admin = context.read<AdminProvider>();
      final books = context.read<BookProvider>();
      final bookId = widget.bookId ?? admin.createBookId();
      var coverUrl = _coverUrl.text.trim();
      if (coverUrl.isEmpty && _coverBytes != null) {
        coverUrl = await admin.uploadCover(
          bookId: bookId,
          bytes: _coverBytes!,
          contentType: _coverContentType,
          onProgress: (value) {
            if (mounted) setState(() => _uploadProgress = value);
          },
        );
      }
      final book = Book(
        id: bookId,
        title: _title.text.trim(),
        author: _author.text.trim(),
        genre: genre,
        description: _description.text.trim(),
        coverUrl: coverUrl,
        price: double.parse(_price.text.trim()),
        isBestseller: _isBestseller,
        releaseDate: _releaseDate,
        popularity: int.parse(_popularity.text.trim()),
        avgRating: _existingBook?.avgRating ?? 0,
        ratingCount: _existingBook?.ratingCount ?? 0,
      );
      if (_isEditing) {
        await admin.updateBook(book);
      } else {
        await admin.createBook(book);
      }
      await books.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.bookSaved)));
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(
              error,
              fallback: AppStrings.adminOperationFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? AppStrings.editBook : AppStrings.addBook;
    if (_isEditing && _isLoading) {
      return AdminScaffold(
        title: title,
        selectedIndex: 1,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_isEditing && _loadError != null) {
      return AdminScaffold(
        title: title,
        selectedIndex: 1,
        child: AdminErrorView(
          message: _loadError!,
          onRetry: () => unawaited(_loadBook()),
        ),
      );
    }
    return AdminScaffold(
      title: title,
      selectedIndex: 1,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                _BookFormSection(
                  title: AppStrings.bookFormDetails,
                  icon: Icons.menu_book_rounded,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: AppStrings.bookTitle,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _author,
                        decoration: const InputDecoration(
                          labelText: AppStrings.bookAuthor,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey<String?>(_genre),
                              initialValue: _genre,
                              decoration: const InputDecoration(
                                labelText: AppStrings.bookGenre,
                              ),
                              items: _genres
                                  .map(
                                    (genre) => DropdownMenuItem(
                                      value: genre,
                                      child: Text(genre),
                                    ),
                                  )
                                  .toList(growable: false),
                              validator:
                                  (value) =>
                                      value == null || value.trim().isEmpty
                                          ? AppStrings.requiredField
                                          : null,
                              onChanged:
                                  (value) => setState(() => _genre = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.filledTonal(
                            tooltip: AppStrings.addNewGenre,
                            onPressed: _isSaving ? null : _addGenre,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _description,
                        decoration: const InputDecoration(
                          labelText: AppStrings.bookDescription,
                          alignLabelWithHint: true,
                        ),
                        minLines: 3,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        validator: _required,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _BookFormSection(
                  title: AppStrings.bookFormPricing,
                  icon: Icons.sell_outlined,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(
                          labelText: AppStrings.bookPrice,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          return number == null ||
                                  !number.isFinite ||
                                  number <= 0
                              ? AppStrings.priceValidation
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _popularity,
                        decoration: const InputDecoration(
                          labelText: AppStrings.popularity,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final number = int.tryParse(value?.trim() ?? '');
                          return number == null || number < 0
                              ? AppStrings.integerValidation
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.releaseDate,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      _releaseDate == null
                                          ? AppStrings.noData
                                          : DateFormat.yMMMd().format(
                                            _releaseDate!,
                                          ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: AppStrings.selectReleaseDate,
                                onPressed:
                                    _isSaving ? null : _chooseReleaseDate,
                                icon: const Icon(Icons.calendar_month_outlined),
                              ),
                              if (_releaseDate != null)
                                IconButton(
                                  tooltip: AppStrings.clearReleaseDate,
                                  onPressed:
                                      _isSaving
                                          ? null
                                          : () => setState(
                                            () => _releaseDate = null,
                                          ),
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppStrings.bestseller),
                        value: _isBestseller,
                        onChanged:
                            _isSaving
                                ? null
                                : (value) =>
                                    setState(() => _isBestseller = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _BookFormSection(
                  title: AppStrings.bookFormCover,
                  icon: Icons.image_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            child: SizedBox(
                              width: 92,
                              height: 128,
                              child:
                                  _coverBytes != null &&
                                          _coverUrl.text.trim().isEmpty
                                      ? Image.memory(
                                        _coverBytes!,
                                        fit: BoxFit.cover,
                                      )
                                      : _coverUrl.text.trim().isNotEmpty
                                      ? Image.network(
                                        _coverUrl.text.trim(),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _CoverPlaceholder(),
                                      )
                                      : const _CoverPlaceholder(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.coverImage,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  AppStrings.coverImageHelp,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _pickCover,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: Text(
                                    _coverBytes != null ||
                                            _coverUrl.text.trim().isNotEmpty
                                        ? AppStrings.replaceCover
                                        : AppStrings.pickCoverImage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _coverUrl,
                        decoration: const InputDecoration(
                          labelText: AppStrings.coverImageUrl,
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final url = value?.trim() ?? '';
                          if (url.isEmpty) return null;
                          final parsed = Uri.tryParse(url);
                          if (parsed == null ||
                              !<String>{
                                'http',
                                'https',
                              }.contains(parsed.scheme) ||
                              parsed.host.isEmpty) {
                            return AppStrings.invalidCoverUrl;
                          }
                          return null;
                        },
                      ),
                      if (_uploadProgress != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${AppStrings.loadingUpload}: ${(_uploadProgress! * 100).round()}%',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GradientButton(
                  onPressed: _isSaving ? null : _save,
                  isLoading: _isSaving,
                  label: AppStrings.save,
                  icon: Icons.save_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? AppStrings.requiredField : null;
}

class _BookFormSection extends StatelessWidget {
  const _BookFormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1.2,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: MidnightGradients.forest,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: MidnightGradients.night,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 36,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );
}
