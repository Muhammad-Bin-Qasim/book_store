import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../models/book.dart';
import 'sample_books.dart';

class BookService {
  BookService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _books =>
      _firestore.collection('books');

  Future<List<Book>> getAllBooks() async {
    try {
      final snapshot = await _books.get();
      return snapshot.docs
          .map((document) => Book.fromMap(document.data(), id: document.id))
          .toList(growable: false);
    } on FirebaseException catch (error) {
      throw BookServiceException(_messageForCode(error.code));
    } catch (error) {
      throw BookServiceException(_genericMessage(error));
    }
  }

  Stream<List<Book>> watchAllBooks() => _books.snapshots().map(
    (snapshot) => snapshot.docs
        .map((document) => Book.fromMap(document.data(), id: document.id))
        .toList(growable: false),
  );

  Future<Book?> getBookById(String id) async {
    try {
      final snapshot = await _books.doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Book.fromMap(data, id: snapshot.id);
    } on FirebaseException catch (error) {
      throw BookServiceException(_messageForCode(error.code));
    } catch (error) {
      throw BookServiceException(_genericMessage(error));
    }
  }

  Future<List<Book>> getBestsellers() async =>
      (await getAllBooks()).where((book) => book.isBestseller).toList();

  Future<List<Book>> getNewArrivals() async {
    final books = (await getAllBooks()).toList();
    books.removeWhere((book) => book.releaseDate == null);
    books.sort((a, b) => b.releaseDate!.compareTo(a.releaseDate!));
    return books;
  }

  Future<List<Book>> getBooksByGenre(String genre) async {
    final normalized = genre.trim().toLowerCase();
    final books = await getAllBooks();
    return books
        .where((book) => book.genre.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  Future<List<Book>> getBooksByAuthor(String author) async {
    final normalized = author.trim().toLowerCase();
    final books = await getAllBooks();
    return books
        .where((book) => book.author.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  Future<List<String>> getGenres() async =>
      _uniqueValues(await getAllBooks(), (book) => book.genre);

  Future<List<String>> getAuthors() async =>
      _uniqueValues(await getAllBooks(), (book) => book.author);

  /// Seeds the sample catalog only when the books collection is empty.
  /// Returns false when existing books caused the seed to be skipped.
  Future<bool> seedSampleBooks() async {
    try {
      final existing = await _books.limit(1).get();
      if (existing.docs.isNotEmpty) return false;

      final batch = _firestore.batch();
      for (final book in sampleBooks) {
        final reference = _books.doc(book.id);
        batch.set(reference, book.toMap());
      }
      await batch.commit();
      return true;
    } on FirebaseException catch (error) {
      throw BookServiceException(_messageForCode(error.code));
    } catch (error) {
      throw BookServiceException(_genericMessage(error));
    }
  }

  static List<String> _uniqueValues(
    List<Book> books,
    String Function(Book) valueOf,
  ) {
    final values =
        books
            .map((book) => valueOf(book).trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  static String friendlyMessage(Object error) {
    return ErrorHandler.message(
      error,
      fallback: AppStrings.catalogGenericError,
    );
  }

  static String _messageForCode(String code) => ErrorHandler.message(
    FirebaseException(plugin: 'cloud_firestore', code: code),
  );

  static String _genericMessage(Object error) =>
      ErrorHandler.message(error, fallback: AppStrings.catalogGenericError);
}

class BookServiceException implements Exception, UserFacingError {
  const BookServiceException(this.message);

  final String message;

  @override
  String get userMessage => message;

  @override
  String toString() => message;
}
