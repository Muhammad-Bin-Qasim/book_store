import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/motion.dart';
import '../providers/cart_provider.dart';
import '../widgets/design_system.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: GlassBar(
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                if (index != navigationShell.currentIndex) {
                  HapticFeedback.selectionClick();
                }
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: AppStrings.home,
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.manage_search_rounded),
                  label: AppStrings.search,
                ),
                NavigationDestination(
                  icon: _CartDestinationIcon(selected: false),
                  selectedIcon: _CartDestinationIcon(selected: true),
                  label: AppStrings.cart,
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: AppStrings.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartDestinationIcon extends StatelessWidget {
  const _CartDestinationIcon({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
        ),
        Positioned(
          right: -10,
          top: -8,
          child: _CartCountBadge(count: count),
        ),
      ],
    );
  }
}


class _CartCountBadge extends StatelessWidget {
  const _CartCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final Widget badge = count == 0
        ? const SizedBox.shrink(key: ValueKey<String>('cart-badge-empty'))
        : Container(
            key: ValueKey<int>(count),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: MidnightGradients.ember,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? AppStrings.cartBadgeMaximum : '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
    if (reduceMotion(context)) return badge;
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.emphasizedCurve,
      switchOutCurve: AppMotion.exitCurve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -.35),
            end: Offset.zero,
          ).animate(animation),
          child: ScaleTransition(scale: animation, child: child),
        ),
      ),
      child: badge,
    );
  }
}
