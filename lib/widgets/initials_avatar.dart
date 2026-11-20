import 'package:flutter/material.dart';

import '../core/app_constants.dart';

/// Theme-aware initials avatar for account and review surfaces.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    this.size = 44,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return AppStrings.initialsFallback;
    if (parts.length == 1) {
      final letters = parts.first.characters;
      return letters.length > 1 ? letters.take(2).toString().toUpperCase() : letters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foregroundColor ?? scheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: size * .32,
        ),
      ),
    );
  }
}
