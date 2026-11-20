import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/book.dart';
import '../services/book_service.dart';

enum BookSortOption { priceLowToHigh, priceHighToLow, popularity, newestFirst }

class BookProvider extends ChangeNotifier {
  BookProvider({BookService? bookService})
    : _bookService = bookService ?? BookService();

  final BookService _bookService;
  StreamSubscription<List<Book>>? _catalogSubscription;
  List<Book> _allBooks = const <Book>[];
  List<Book> _bestsellers = const <Book>[];
  List<Book> _newArrivals = const <Book>[];
  List<String> _genres = const <String>[];
  List<String> _authors = const <String>[];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _query = '';
  String? _selectedGenre;
  String? _selectedAuthor;
  BookSortOption _sortOption = BookSortOption.popularity;
  RangeValues? _priceRange;

  List<Book> get allBooks => List<Book>.unmodifiable(_allBooks);
  List<Book> get bestsellers => List<Book>.unmodifiable(_bestsellers);
  List<Book> get newArrivals => List<Book>.unmodifiable(_newArrivals);
  List<String> get genres => List<String>.unmodifiable(_genres);
  List<String> get authors => List<String>.unmodifiable(_authors);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get selectedGenre => _selectedGenre;
  String? get selectedAuthor => _selectedAuthor;
  BookSortOption get sortOption => _sortOption;
  RangeValues? get priceRange => _priceRange;

  List<Book> get filteredBooks {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered =
        _allBooks.where((book) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              book.title.toLowerCase().contains(normalizedQuery) ||
              book.author.toLowerCase().contains(normalizedQuery) ||
              book.genre.toLowerCase().contains(normalizedQuery);
          final matchesGenre =
              _selectedGenre == null ||
              book.genre.toLowerCase() == _selectedGenre!.toLowerCase();
          final matchesAuthor =
              _selectedAuthor == null ||
              book.author.toLowerCase() == _selectedAuthor!.toLowerCase();
          final matchesPrice =
              _priceRange == null ||
              (book.price >= _priceRange!.start &&
                  book.price <= _priceRange!.end);
          return matchesQuery && matchesGenre && matchesAuthor && matchesPrice;
        }).toList();

    switch (_sortOption) {
      case BookSortOption.priceLowToHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case BookSortOption.priceHighToLow:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case BookSortOption.popularity:
        filtered.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case BookSortOption.newestFirst:
        filtered.sort(
          (a, b) => (b.releaseDate ?? DateTime(1900)).compareTo(
            a.releaseDate ?? DateTime(1900),
          ),
        );
        break;
    }
    return filtered;
  }

  Future<void> loadCatalog({bool forceRefresh = false}) async {
    if (_isLoading || (_hasLoaded && !forceRefresh)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final books = await _bookService.getAllBooks();
      _applyCatalog(books);
      _hasLoaded = true;
      _listenToCatalog();
    } catch (error) {
      _errorMessage = ErrorHandler.message(
        error,
        fallback: AppStrings.catalogGenericError,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToCatalog() {
    unawaited(_catalogSubscription?.cancel());
    _catalogSubscription = _bookService.watchAllBooks().listen(
      (books) {
        _applyCatalog(books);
        _hasLoaded = true;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = ErrorHandler.message(
          error,
          fallback: AppStrings.catalogGenericError,
        );
        notifyListeners();
      },
    );
  }

  void _applyCatalog(List<Book> books) {
    _allBooks = books;
    _bestsellers =
        books.where((book) => book.isBestseller).toList()
          ..sort((a, b) => b.popularity.compareTo(a.popularity));
    _newArrivals =
        books.where((book) => book.releaseDate != null).toList()
          ..sort((a, b) => b.releaseDate!.compareTo(a.releaseDate!));
    _genres = _unique(books.map((book) => book.genre));
    _authors = _unique(books.map((book) => book.author));
  }

  Future<void> refresh() => loadCatalog(forceRefresh: true);

  Future<bool> seedSampleBooks() => _bookService.seedSampleBooks();

  Book? findBookById(String id) {
    for (final book in _allBooks) {
      if (book.id == id) return book;
    }
    return null;
  }

  Future<Book?> getBookById(String id) async {
    final cached = _allBooks.where((book) => book.id == id);
    if (cached.isNotEmpty) return cached.first;
    return _bookService.getBookById(id);
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setGenre(String? value) {
    if (_selectedGenre == value) return;
    _selectedGenre = value;
    notifyListeners();
  }

  void setAuthor(String? value) {
    if (_selectedAuthor == value) return;
    _selectedAuthor = value;
    notifyListeners();
  }

  void setSort(BookSortOption value) {
    if (_sortOption == value) return;
    _sortOption = value;
    notifyListeners();
  }

  void setPriceRange(RangeValues? value) {
    if (_priceRange == value) return;
    _priceRange = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _selectedGenre = null;
    _selectedAuthor = null;
    _priceRange = null;
    _sortOption = BookSortOption.popularity;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_catalogSubscription?.cancel());
    super.dispose();
  }

  static List<String> _unique(Iterable<String> values) =>
      values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
