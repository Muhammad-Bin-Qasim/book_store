import 'package:flutter/material.dart';

import '../core/app_constants.dart';

class RatingBar extends StatelessWidget {
  const RatingBar({
    required this.rating,
    this.ratingCount,
    this.compact = false,
    super.key,
  });

  final double rating;
  final int? ratingCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.tertiary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!compact && ratingCount != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($ratingCount)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
