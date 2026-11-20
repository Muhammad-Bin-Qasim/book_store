import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'core/app_constants.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/book_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/review_provider.dart';
import 'providers/wishlist_provider.dart';
import 'widgets/connectivity_banner.dart';

class BookStoreApp extends StatefulWidget {
  const BookStoreApp({required this.themeController, super.key});

  final ThemeController themeController;

  @override
  State<BookStoreApp> createState() => _BookStoreAppState();
}

class _BookStoreAppState extends State<BookStoreApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createAppRouter(_authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(
          value: widget.themeController,
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, auth, admin) =>
              admin!
                ..bind(userId: auth.currentUser?.uid, isAdmin: auth.isAdmin),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, orders) => orders!..bind(auth.currentUser?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReviewProvider>(
          create: (_) => ReviewProvider(),
          update: (_, auth, reviews) => reviews!..bind(auth.currentUser?.uid),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, BookProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, books, cart) =>
              cart!..bind(auth.currentUser?.uid, books),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          BookProvider,
          WishlistProvider
        >(
          create: (_) => WishlistProvider(),
          update: (_, auth, books, wishlist) =>
              wishlist!..bind(auth.currentUser?.uid, books),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            routerConfig: _router,
            builder: (context, child) {
              final theme = Theme.of(context);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemUiOverlayStyle(theme),
                child: ConnectivityBanner(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
