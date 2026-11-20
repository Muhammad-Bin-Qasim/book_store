import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/motion.dart';
import '../core/app_routes.dart';
import '../models/book.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../services/review_service.dart';
import 'empty_state.dart';
import 'error_view.dart';
import 'design_system.dart';
import 'initials_avatar.dart';
import 'rating_bar.dart';

class ReviewsSection extends StatefulWidget {
  const ReviewsSection({required this.book, super.key});
  final Book book;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  late ReviewProvider _reviewProvider;

  @override
  void initState() {
    super.initState();
    _reviewProvider = context.read<ReviewProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reviewProvider.openBook(widget.book.id);
    });
  }

  @override
  void didUpdateWidget(covariant ReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _reviewProvider.closeBook(oldWidget.book.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reviewProvider.openBook(widget.book.id);
      });
    }
  }

  @override
  void dispose() {
    _reviewProvider.closeBook(widget.book.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final reviews = provider.sortedReviewsFor(widget.book.id);
    final ownReview = provider.myReviewFor(widget.book.id);
    final theme = Theme.of(context);
    final total = reviews.length;
    final distribution = <int, int>{
      for (var stars = 1; stars <= 5; stars++)
        stars: reviews.where((review) => review.rating.round() == stars).length,
    };
    return Card(
      elevation: 1.1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.reviews, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                RatingBar(
                  rating: widget.book.avgRating,
                  ratingCount: widget.book.ratingCount,
                ),
                Text(
                  AppStrings.reviewSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (total == 0)
              Text(
                AppStrings.noRatingDistribution,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...List<Widget>.generate(5, (index) {
                final stars = 5 - index;
                final count = distribution[stars] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: Row(
                          children: [
                            Text('$stars'),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: theme.colorScheme.tertiary,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: total == 0 ? 0 : count / total,
                          ),
                          duration: AppMotion.duration(context, AppMotion.emphasis),
                          curve: Curves.easeOutCubic,
                          builder:
                              (context, value, _) => LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                color: theme.colorScheme.primary,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 28,
                        child: Text('$count', textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _openReviewForm(ownReview),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                    ownReview == null
                        ? AppStrings.writeReview
                        : AppStrings.editYourReview,
                  ),
                ),
                DropdownButton<ReviewSortOption>(
                  value: provider.sortOption,
                  onChanged: (value) {
                    if (value != null) provider.setSortOption(value);
                  },
                  items: const <DropdownMenuItem<ReviewSortOption>>[
                    DropdownMenuItem(
                      value: ReviewSortOption.newest,
                      child: Text(AppStrings.reviewSortNewest),
                    ),
                    DropdownMenuItem(
                      value: ReviewSortOption.mostLiked,
                      child: Text(AppStrings.reviewSortMostLiked),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (provider.isLoading(widget.book.id))
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.errorFor(widget.book.id) != null)
              ErrorView(
                title: AppStrings.reviewSaveFailed,
                message: provider.errorFor(widget.book.id),
                onRetry: () => provider.retry(widget.book.id),
              )
            else if (reviews.isEmpty)
              const EmptyState(
                icon: Icons.rate_review_outlined,
                title: AppStrings.reviewEmptyTitle,
                message: AppStrings.reviewEmptyMessage,
              )
            else
              ...reviews.map(
                (review) => _ReviewTile(
                  review: review,
                  onLike: () => _toggleLike(review),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReviewForm(Review? existing) async {
    if (context.read<AuthProvider>().currentUser == null) {
      context.goNamed(AppRoutes.loginName);
      return;
    }
    final result = await showModalBottomSheet<_ReviewFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReviewFormSheet(existing: existing),
    );
    if (result == null || !mounted) return;
    final provider = context.read<ReviewProvider>();
    try {
      if (result.delete) {
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder:
                  (dialogContext) => AlertDialog(
                    title: const Text(AppStrings.reviewDeleteConfirmationTitle),
                    content: const Text(
                      AppStrings.reviewDeleteConfirmationMessage,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text(AppStrings.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text(AppStrings.deleteReview),
                      ),
                    ],
                  ),
            ) ??
            false;
        if (!confirmed || !mounted) return;
        await provider.deleteReview(widget.book.id);
        if (!mounted) return;
        _showMessage(AppStrings.reviewDeleted);
        return;
      }
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      await provider.addOrUpdateReview(
        bookId: widget.book.id,
        userName:
            user.name.isEmpty ? AppStrings.accountNameUnavailable : user.name,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      _showMessage(AppStrings.reviewSaved);
    } catch (error) {
      if (!mounted) return;
      _showMessage(ReviewService.friendlyMessage(error));
    }
  }

  Future<void> _toggleLike(Review review) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      context.goNamed(AppRoutes.loginName);
      return;
    }
    try {
      await context.read<ReviewProvider>().toggleLike(widget.book.id, review);
    } catch (error) {
      if (!mounted) return;
      _showMessage(ReviewService.friendlyMessage(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.onLike});
  final Review review;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final uid = context.watch<AuthProvider>().currentUser?.uid;
    final ownReview = uid != null && uid == review.userId;
    final liked = uid != null && review.isLikedBy(uid);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .48),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: review.userName, size: 42),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName.isEmpty
                            ? AppStrings.accountNameUnavailable
                            : review.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      RatingBar(rating: review.rating, compact: true),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    DateFormat.yMMMd().format(review.createdAt),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message:
                    ownReview
                        ? AppStrings.reviewCannotLikeOwn
                        : liked
                        ? AppStrings.reviewUnlike
                        : AppStrings.reviewLike,
                child: Semantics(
                  button: true,
                  enabled: !ownReview,
                  child: PressScale(
                    onTap: ownReview ? null : onLike,
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.quick),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: liked ? scheme.primaryContainer : scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: liked ? scheme.primary : scheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: AppMotion.duration(context, AppMotion.quick),
                            transitionBuilder:
                                (child, animation) => ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                            child: Icon(
                              liked
                                  ? Icons.thumb_up_rounded
                                  : Icons.thumb_up_outlined,
                              key: ValueKey<bool>(liked),
                              size: 18,
                              color:
                                  liked
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${review.likes}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewFormResult {
  const _ReviewFormResult({
    this.delete = false,
    this.rating = 5,
    this.comment = '',
  });
  final bool delete;
  final int rating;
  final String comment;
}

class _ReviewFormSheet extends StatefulWidget {
  const _ReviewFormSheet({required this.existing});
  final Review? existing;

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _comment;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController(text: widget.existing?.comment ?? '');
    _rating = widget.existing?.rating.round() ?? 5;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? AppStrings.writeReview
                    : AppStrings.editYourReview,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.reviewRatingLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                children: List<Widget>.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: '$value',
                    onPressed: () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: theme.colorScheme.tertiary,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _comment,
                maxLines: 5,
                minLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: AppStrings.reviewCommentLabel,
                  hintText: AppStrings.reviewCommentHint,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final length = (value ?? '').trim().length;
                  return length < 3 || length > 500
                      ? AppStrings.reviewCommentValidation
                      : null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) return;
                  Navigator.of(context).pop(
                    _ReviewFormResult(
                      rating: _rating,
                      comment: _comment.text.trim(),
                    ),
                  );
                },
                child: const Text(AppStrings.reviewSave),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(const _ReviewFormResult(delete: true)),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text(AppStrings.deleteReview),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
