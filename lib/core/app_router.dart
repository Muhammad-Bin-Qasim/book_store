import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_books_screen.dart';
import '../screens/admin/manage_orders_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/admin_book_form_screen.dart';
import '../screens/admin/admin_order_details_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/cart/order_confirmation_screen.dart';
import '../screens/home/book_details_screen.dart';
import '../screens/home/category_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/main_shell.dart';
import '../screens/not_found_screen.dart';
import '../screens/profile/order_details_screen.dart';
import '../screens/profile/orders_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/wishlist_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';
import 'motion.dart';

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    redirect: (context, state) =>
        _redirect(authProvider, state.matchedLocation),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: AppRoutes.resetPasswordName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const ResetPasswordScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: AppRoutes.searchName,
                pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const SearchScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                name: AppRoutes.cartName,
                pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  const CartScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                pageBuilder: (context, state) => _routePage(
                  context,
                  state,
                  ProfileScreen(
                    openAddressFormOnLoad:
                        state.uri.queryParameters[AppRoutes.profileAddressQuery] ==
                        'true',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.bookDetails,
        name: AppRoutes.bookDetailsName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          BookDetailsScreen(bookId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.category,
        name: AppRoutes.categoryName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          CategoryScreen(
            type: state.uri.queryParameters[AppRoutes.categoryQueryType] ??
                AppRoutes.categoryTypeGenre,
            value: state.uri.queryParameters[AppRoutes.categoryQueryValue] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        name: AppRoutes.orderConfirmationName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          OrderConfirmationScreen(
            args: state.extra is OrderConfirmationArgs
                ? state.extra! as OrderConfirmationArgs
                : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: AppRoutes.checkoutName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const CheckoutScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        name: AppRoutes.wishlistName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const WishlistScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: AppRoutes.ordersName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const OrdersScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderDetails,
        name: AppRoutes.orderDetailsName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          OrderDetailsScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: AppRoutes.adminDashboardName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.manageBooks,
        name: AppRoutes.manageBooksName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const ManageBooksScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.manageUsers,
        name: AppRoutes.manageUsersName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const ManageUsersScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminBookCreate,
        name: AppRoutes.adminBookCreateName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const AdminBookFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminBookEdit,
        name: AppRoutes.adminBookEditName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          AdminBookFormScreen(bookId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminOrderDetails,
        name: AppRoutes.adminOrderDetailsName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          AdminOrderDetailsScreen(
            orderId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.manageOrders,
        name: AppRoutes.manageOrdersName,
        pageBuilder: (context, state) => _routePage(
          context,
          state,
          const ManageOrdersScreen(),
        ),
      ),
    ],
  );
}

CustomTransitionPage<void> _routePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final reduced = reduceMotion(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: reduced ? Duration.zero : AppMotion.standard,
    reverseTransitionDuration: reduced ? Duration.zero : AppMotion.standard,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotion(context)) return child;
      final curve = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.exitCurve,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.035, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

String? _redirect(AuthProvider auth, String location) {
  if (auth.showDisabledAccountNotice && location != AppRoutes.login) {
    return AppRoutes.login;
  }

  if (auth.isInitializing) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final destination = auth.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home;

  if (location == AppRoutes.splash) {
    return auth.isLoggedIn ? destination : AppRoutes.home;
  }

  if (auth.isLoggedIn) {
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return destination;
    }
    if (location.startsWith(AppRoutes.adminDashboard) && !auth.isAdmin) {
      return AppRoutes.home;
    }
    return null;
  }

  if (_requiresAuthentication(location)) return AppRoutes.login;
  return null;
}

bool _requiresAuthentication(String location) {
  const protectedPaths = <String>{
    AppRoutes.cart,
    AppRoutes.profile,
    AppRoutes.checkout,
    AppRoutes.wishlist,
    AppRoutes.orders,
  };
  return protectedPaths.contains(location) ||
      location.startsWith(AppRoutes.orders) ||
      location.startsWith(AppRoutes.orderConfirmation) ||
      location.startsWith(AppRoutes.adminDashboard);
}
