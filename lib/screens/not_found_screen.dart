import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_constants.dart';
import '../core/app_routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.unknownRouteTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.find_in_page_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.unknownRouteMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(AppStrings.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
