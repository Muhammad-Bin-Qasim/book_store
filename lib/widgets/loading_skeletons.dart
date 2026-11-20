import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import 'design_system.dart';

/// Home-shaped placeholder for the featured panel and book rail.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBox(height: 190, radius: AppRadii.xl),
        const SizedBox(height: AppSpacing.lg),
        const ShimmerBox(width: 142, height: 22, radius: AppRadii.pill),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 178,
          child: Row(
            children: const [
              Expanded(child: _SkeletonBookCard()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _SkeletonBookCard()),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A responsive grid of book-card-shaped placeholders.
class BookGridSkeleton extends StatelessWidget {
  const BookGridSkeleton({
    required this.columns,
    this.itemCount = 8,
    this.childAspectRatio = .57,
    this.mainAxisExtent,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final int columns;
  final int itemCount;
  final double childAspectRatio;
  final double? mainAxisExtent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: padding,
    itemCount: itemCount,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: childAspectRatio,
      mainAxisExtent: mainAxisExtent,
    ),
    itemBuilder: (context, index) => const _SkeletonBookCard(),
  );
}

/// Cart row placeholders mirror the cover, title, quantity, and price layout.
class CartListSkeleton extends StatelessWidget {
  const CartListSkeleton({this.itemCount = 3, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.md),
    itemCount: itemCount,
    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) => Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 72, height: 98, radius: AppRadii.md),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 3),
                  ShimmerBox(height: 15, radius: AppRadii.pill),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerBox(width: 112, height: 12, radius: AppRadii.pill),
                  SizedBox(height: AppSpacing.md),
                  ShimmerBox(width: 78, height: 30, radius: AppRadii.pill),
                  SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ShimmerBox(width: 68, height: 16, radius: AppRadii.pill),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Order cards preserve the real card's identifier, date, status, and total rows.
class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Expanded(child: ShimmerBox(width: 145, height: 18, radius: AppRadii.pill)),
                    ShimmerBox(width: 82, height: 25, radius: AppRadii.pill),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                ShimmerBox(width: 96, height: 13, radius: AppRadii.pill),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(width: 85, height: 14, radius: AppRadii.pill)),
                    ShimmerBox(width: 76, height: 17, radius: AppRadii.pill),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Wishlist placeholders match the two-column saved-book cards.
class WishlistGridSkeleton extends StatelessWidget {
  const WishlistGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => BookGridSkeleton(
      columns: constraints.maxWidth >= 760 ? 3 : 2,
      itemCount: 6,
      mainAxisExtent: constraints.maxWidth < 400 ? 350 : 370,
    ),
  );
}

class _SkeletonBookCard extends StatelessWidget {
  const _SkeletonBookCard();

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: ShimmerBox(radius: AppRadii.md)),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(width: double.infinity, height: 14, radius: AppRadii.pill),
          SizedBox(height: AppSpacing.xs),
          ShimmerBox(width: 92, height: 12, radius: AppRadii.pill),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(width: 68, height: 15, radius: AppRadii.pill),
        ],
      ),
    ),
  );
}
