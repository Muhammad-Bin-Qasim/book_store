import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import 'design_system.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({this.message = AppStrings.loading, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShimmerBox(width: 92, height: 120, radius: AppRadii.md),
              const SizedBox(height: AppSpacing.md),
              const ShimmerBox(width: 180, height: 14, radius: AppRadii.pill),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
