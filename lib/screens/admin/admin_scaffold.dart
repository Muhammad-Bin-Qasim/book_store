import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../providers/auth_provider.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    required this.title,
    required this.selectedIndex,
    required this.child,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final int selectedIndex;
  final Widget child;
  final Widget? floatingActionButton;

  static const double _wideBreakpoint = 840;

  static const List<_AdminDestination> _destinations = <_AdminDestination>[
    _AdminDestination(
      AppStrings.dashboardTab,
      Icons.dashboard_outlined,
      Icons.dashboard_rounded,
      AppRoutes.adminDashboard,
    ),
    _AdminDestination(
      AppStrings.booksTab,
      Icons.menu_book_outlined,
      Icons.menu_book_rounded,
      AppRoutes.manageBooks,
    ),
    _AdminDestination(
      AppStrings.orders,
      Icons.local_shipping_outlined,
      Icons.local_shipping_rounded,
      AppRoutes.manageOrders,
    ),
    _AdminDestination(
      AppStrings.usersTab,
      Icons.people_outline_rounded,
      Icons.people_rounded,
      AppRoutes.manageUsers,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          drawer: isWide ? null : _buildDrawer(context),
          floatingActionButton: floatingActionButton,
          body:
              isWide
                  ? Row(
                    children: <Widget>[
                      NavigationRail(
                        selectedIndex: selectedIndex,
                        extended: constraints.maxWidth >= 1120,
                        onDestinationSelected:
                            (index) => _goToDestination(context, index),
                        destinations: _destinations
                            .map(
                              (destination) => NavigationRailDestination(
                                icon: Icon(destination.icon),
                                selectedIcon: Icon(destination.selectedIcon),
                                label: Text(destination.label),
                              ),
                            )
                            .toList(growable: false),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            if (constraints.maxWidth >= 1120)
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: OutlinedButton.icon(
                                  onPressed:
                                      () => context.goNamed(AppRoutes.homeName),
                                  icon: const Icon(Icons.storefront_outlined),
                                  label: const Text(AppStrings.backToStore),
                                ),
                              )
                            else
                              IconButton(
                                tooltip: AppStrings.backToStore,
                                onPressed:
                                    () => context.goNamed(AppRoutes.homeName),
                                icon: const Icon(Icons.storefront_outlined),
                              ),
                            if (constraints.maxWidth >= 1120)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.sm,
                                  0,
                                  AppSpacing.sm,
                                  AppSpacing.md,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () => _logout(context),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text(AppStrings.logout),
                                ),
                              )
                            else
                              IconButton(
                                tooltip: AppStrings.logout,
                                onPressed: () => _logout(context),
                                icon: const Icon(Icons.logout_rounded),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  )
                  : child,
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                AppStrings.adminSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var index = 0; index < _destinations.length; index++)
              ListTile(
                leading: Icon(_destinations[index].icon),
                title: Text(_destinations[index].label),
                selected: selectedIndex == index,
                onTap:
                    () => _goToDestination(context, index, closeDrawer: true),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text(AppStrings.backToStore),
              onTap: () {
                Navigator.of(context).pop();
                context.goNamed(AppRoutes.homeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text(AppStrings.logout),
              onTap: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToDestination(
    BuildContext context,
    int index, {
    bool closeDrawer = false,
  }) {
    if (closeDrawer) Navigator.of(context).pop();
    final route = _destinations[index].route;
    switch (route) {
      case AppRoutes.adminDashboard:
        context.goNamed(AppRoutes.adminDashboardName);
        break;
      case AppRoutes.manageBooks:
        context.goNamed(AppRoutes.manageBooksName);
        break;
      case AppRoutes.manageOrders:
        context.goNamed(AppRoutes.manageOrdersName);
        break;
      case AppRoutes.manageUsers:
        context.goNamed(AppRoutes.manageUsersName);
        break;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final succeeded = await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    if (!succeeded) {
      final message =
          context.read<AuthProvider>().errorMessage ??
          AppStrings.authGenericError;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    context.goNamed(AppRoutes.homeName);
  }
}

class _AdminDestination {
  const _AdminDestination(this.label, this.icon, this.selectedIcon, this.route);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
