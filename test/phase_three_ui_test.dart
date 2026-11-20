import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:book_store/core/app_constants.dart';
import 'package:book_store/core/app_theme.dart';
import 'package:book_store/models/app_user.dart';
import 'package:book_store/models/book.dart';
import 'package:book_store/models/review.dart';
import 'package:book_store/providers/auth_provider.dart';
import 'package:book_store/providers/book_provider.dart';
import 'package:book_store/providers/cart_provider.dart';
import 'package:book_store/providers/review_provider.dart';
import 'package:book_store/providers/wishlist_provider.dart';
import 'package:book_store/screens/home/book_details_screen.dart';
import 'package:book_store/screens/home/home_screen.dart';
import 'package:book_store/services/auth_service.dart';
import 'package:book_store/services/book_service.dart';
import 'package:book_store/services/cart_service.dart';
import 'package:book_store/services/review_service.dart';
import 'package:book_store/services/wishlist_service.dart';

void main() {
  for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
    final themeName = theme.brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('Home remains overflow-free at 360dp in $themeName mode', (
      tester,
    ) async {
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final providers = _TestProviders();
      addTearDown(providers.dispose);

      await tester.pumpWidget(_testApp(theme, providers, const HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      _expectNoFlutterException(tester);
      final scrollView = find.byType(CustomScrollView).first;
      for (var index = 0; index < 5; index++) {
        await tester.drag(scrollView, const Offset(0, -540));
        await tester.pumpAndSettle();
        _expectNoFlutterException(tester);
      }
    });

    testWidgets(
      'Book details remains overflow-free at 360dp in $themeName mode',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final providers = _TestProviders();
        addTearDown(providers.dispose);

        await tester.pumpWidget(
          _testApp(theme, providers, const BookDetailsScreen(bookId: 'book-1')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final scrollView = find.byType(CustomScrollView).first;
        for (var index = 0; index < 5; index++) {
          await tester.drag(scrollView, const Offset(0, -560));
          await tester.pumpAndSettle();
          _expectNoFlutterException(tester);
        }
      },
    );
  }

  testWidgets('Featured carousel pauses for touch and resumes afterward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final providers = _TestProviders();
    addTearDown(providers.dispose);

    await tester.pumpWidget(
      _testApp(
        AppTheme.light,
        providers,
        const HomeScreen(),
        disableAnimations: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final carouselSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == AppStrings.featuredBooks,
    );
    expect(
      tester.widget<Semantics>(carouselSemantics).properties.value,
      AppStrings.featuredPageFormat(1, 5),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView).first),
    );
    await gesture.moveBy(const Offset(28, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(-28, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 6));
    expect(
      tester.widget<Semantics>(carouselSemantics).properties.value,
      AppStrings.featuredPageFormat(1, 5),
    );

    await gesture.up();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Semantics>(carouselSemantics).properties.value,
      AppStrings.featuredPageFormat(2, 5),
    );
  });

  testWidgets('Featured carousel honors reduced motion', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final providers = _TestProviders();
    addTearDown(providers.dispose);

    await tester.pumpWidget(
      _testApp(AppTheme.light, providers, const HomeScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 6));

    final carouselSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == AppStrings.featuredBooks,
    );
    expect(
      tester.widget<Semantics>(carouselSemantics).properties.value,
      AppStrings.featuredPageFormat(1, 5),
    );
    expect(tester.takeException(), isNull);
  });
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception != null) debugPrint(exception.toString());
  expect(exception, isNull);
}

Widget _testApp(
  ThemeData theme,
  _TestProviders providers,
  Widget home, {
  bool disableAnimations = true,
}) {
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<BookProvider>.value(value: providers.books),
      ChangeNotifierProvider<AuthProvider>.value(value: providers.auth),
      ChangeNotifierProvider<WishlistProvider>.value(value: providers.wishlist),
      ChangeNotifierProvider<CartProvider>.value(value: providers.cart),
      ChangeNotifierProvider<ReviewProvider>.value(value: providers.reviews),
    ],
    child: MaterialApp(
      theme: theme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(1.3),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        );
      },
      home: home,
    ),
  );
}

class _TestProviders {
  _TestProviders() {
    books = BookProvider(bookService: _FakeBookService(_testBooks));
    auth = AuthProvider(authService: _FakeAuthService());
    wishlist = WishlistProvider(wishlistService: _FakeWishlistService());
    cart = CartProvider(cartService: _FakeCartService());
    reviews = ReviewProvider(reviewService: _FakeReviewService());
  }

  late final BookProvider books;
  late final AuthProvider auth;
  late final WishlistProvider wishlist;
  late final CartProvider cart;
  late final ReviewProvider reviews;

  void dispose() {
    books.dispose();
    auth.dispose();
    wishlist.dispose();
    cart.dispose();
    reviews.dispose();
  }
}

final List<Book> _testBooks = List<Book>.generate(
  6,
  (index) => Book(
    id: 'book-$index',
    title:
        index == 1
            ? 'A Thoughtfully Long Title About Stories and the People Who Read Them'
            : 'A Library of Wandering Stars',
    author: 'Avery Morgan',
    genre: index.isEven ? 'Fantasy' : 'Mystery',
    description:
        'A richly imagined story follows its characters across a changing '
        'landscape. Every chapter reveals a new perspective, while old '
        'questions gain meaning as the journey unfolds. This longer passage '
        'lets the details screen exercise its expandable description layout '
        'at larger text sizes.',
    coverUrl: '',
    price: 1250 + index * 175,
    isBestseller: index < 5,
    releaseDate: DateTime(2026, 10, 1 + index),
    popularity: 100 - index,
    avgRating: 4.4,
    ratingCount: 12,
  ),
);

class _FakeBookService implements BookService {
  _FakeBookService(this.books);

  final List<Book> books;

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  Stream<List<Book>> watchAllBooks() => Stream<List<Book>>.value(books);

  @override
  Future<Book?> getBookById(String id) async {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService implements AuthService {
  @override
  Stream<AppUser?> get authStateChanges => const Stream<AppUser?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWishlistService implements WishlistService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCartService implements CartService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReviewService implements ReviewService {
  @override
  Stream<List<Review>> streamBookReviews(String bookId) =>
      Stream<List<Review>>.value(const <Review>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
