import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';

class GlobalErrorFallback extends StatelessWidget {
  const GlobalErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.light;
    return Material(
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            AppStrings.genericError,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
