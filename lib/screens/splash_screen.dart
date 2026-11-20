import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/motion.dart';
import '../widgets/design_system.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: MidnightGradients.night),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -40,
              child: _GlowOrb(
                size: 240,
                color: theme.colorScheme.primary.withValues(alpha: .28),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -50,
              child: _GlowOrb(
                size: 280,
                color: theme.colorScheme.secondary.withValues(alpha: .12),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: .82, end: 1),
                      duration: AppMotion.duration(context, AppMotion.emphasis),
                      curve: Curves.elasticOut,
                      builder:
                          (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.onDarkAccent.withValues(alpha: .1),
                          border: Border.all(
                            color: AppColors.onDarkAccent.withValues(alpha: .28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: .27,
                              ),
                              blurRadius: 42,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 58,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: AppMotion.duration(context, AppMotion.standard),
                      builder:
                          (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - value)),
                              child: child,
                            ),
                          ),
                      child: Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.onDarkAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.splashTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onDarkAccent,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: 26,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 24,
                color: AppColors.onDarkAccent.withValues(alpha: .12),
              ),
            ),
            Positioned(
              right: 34,
              bottom: 86,
              child: Icon(
                Icons.menu_book_rounded,
                size: 34,
                color: AppColors.onDarkAccent.withValues(alpha: .12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
