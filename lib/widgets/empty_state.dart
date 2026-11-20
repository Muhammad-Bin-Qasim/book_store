import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import 'design_system.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.accentIcon = Icons.menu_book_rounded,
    super.key,
  });

  final IconData icon;
  final IconData accentIcon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyIllustration(icon: icon, accentIcon: accentIcon),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration({required this.icon, required this.accentIcon});

  final IconData icon;
  final IconData accentIcon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    height: 124,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            gradient: MidnightGradients.ember,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: .16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        Positioned(
          top: 2,
          right: 1,
          child: _OrbitIcon(icon: accentIcon, size: 36),
        ),
        Positioned(
          bottom: 1,
          left: 2,
          child: _OrbitIcon(icon: Icons.auto_awesome_rounded, size: 30),
        ),
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSecondary),
      ],
    ),
  );
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: .12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, size: size * .52, color: Theme.of(context).colorScheme.primary),
  );
}
