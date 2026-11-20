import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../models/order.dart';

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({required this.status, super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = switch (status) {
      OrderStatus.placed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      OrderStatus.shipped => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      OrderStatus.outForDelivery => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      OrderStatus.delivered => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
      OrderStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Chip(
      label: Text(status.label),
      backgroundColor: colors.$1,
      labelStyle: TextStyle(color: colors.$2),
      visualDensity: VisualDensity.compact,
    );
  }
}

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    ),
  );
}

class AdminBookThumbnail extends StatelessWidget {
  const AdminBookThumbnail({required this.url, super.key});
  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.sm),
    child: SizedBox(
      width: 44,
      height: 58,
      child:
          url.isEmpty
              ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.menu_book_outlined),
              )
              : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.broken_image_outlined),
              ),
    ),
  );
}
