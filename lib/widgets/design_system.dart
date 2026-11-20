import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../core/motion.dart';

class MidnightGradients {
  MidnightGradients._();

  static const forest = LinearGradient(
    colors: [Color(0xFF153B2F), Color(0xFF28725C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ember = LinearGradient(
    colors: [AppColors.amber, AppColors.coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const night = LinearGradient(
    colors: [Color(0xFF0F1F1A), Color(0xFF24513F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const indigo = LinearGradient(
    colors: [Color(0xFF344B70), Color(0xFF55406C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const alert = LinearGradient(
    colors: [AppColors.alertRed, AppColors.alertRedLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.gradient = MidnightGradients.forest,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return AnimatedOpacity(
      duration: AppMotion.duration(context, AppMotion.quick),
      opacity: enabled ? 1 : .58,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow
                    .withValues(alpha: .2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: Center(
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onDarkAccent,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: AppColors.onDarkAccent),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.onDarkAccent,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBar extends StatelessWidget {
  const GlassBar({
    required this.child,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .7),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: .14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 5),
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  gradient: MidnightGradients.ember,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    this.width,
    this.height,
    this.radius = AppRadii.md,
    super.key,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = reduceMotion(context);
    if (_reduced == reduced && (_controller.isAnimating || reduced)) return;
    _reduced = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest.withValues(alpha: .66);
    final highlight = Color.lerp(base, scheme.surface, .62)!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final shift = _reduced ? 0.0 : _controller.value * 3.2 - 1.6;
          return LinearGradient(
            begin: Alignment(-1.5 + shift, -.2),
            end: Alignment(-.5 + shift, .2),
            colors: [base, highlight, base],
            stops: const [0, .5, 1],
          ).createShader(bounds);
        },
        child: child,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Button used by book purchase actions: haptic feedback and a single bounce.
class AddToCartMotionButton extends StatefulWidget {
  const AddToCartMotionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<AddToCartMotionButton> createState() => _AddToCartMotionButtonState();
}

class _AddToCartMotionButtonState extends State<AddToCartMotionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.emphasis,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: .97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: .97, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: reduceMotion(context) ? const AlwaysStoppedAnimation<double>(1) : _scale,
    child: GradientButton(
      label: widget.label,
      icon: Icons.shopping_cart_outlined,
      isLoading: widget.isLoading,
      onPressed: widget.onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              if (!reduceMotion(context)) _controller.forward(from: 0);
              widget.onPressed!();
            },
    ),
  );
}

class AnimatedHeart extends StatelessWidget {
  const AnimatedHeart({
    required this.selected,
    required this.onTap,
    this.tooltip,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.error : scheme.onSurface;
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.quick),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey<bool>(selected),
          color: color,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.gradient = MidnightGradients.forest,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.onDarkAccent.withValues(alpha: .9)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onDarkAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.onDarkAccent),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final foreground = color == null ? tint : scheme.onSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color == null ? tint.withValues(alpha: .12) : tint,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class StepTimeline extends StatelessWidget {
  const StepTimeline({
    required this.steps,
    required this.currentStep,
    super.key,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: index == 0
                          ? const SizedBox(height: 2)
                          : Container(
                              height: 2,
                              color: index <= currentStep
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                    ),
                    AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.standard),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: index <= currentStep
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index <= currentStep
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: index < currentStep
                          ? Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: scheme.onPrimary,
                            )
                          : null,
                    ),
                    Expanded(
                      child: index == steps.length - 1
                          ? const SizedBox(height: 2)
                          : Container(
                              height: 2,
                              color: index < currentStep
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: index <= currentStep
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PressScale extends StatefulWidget {
  const PressScale({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: reduceMotion(context) || !_pressed ? 1 : .97,
        duration: AppMotion.duration(context, AppMotion.quick),
        child: widget.child,
      ),
    );
  }
}

class AuthHero extends StatelessWidget {
  const AuthHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 186,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: MidnightGradients.forest,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -34,
            child: Icon(
              icon,
              size: 150,
              color: AppColors.onDarkAccent.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.onDarkAccent.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: AppColors.onDarkAccent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onDarkAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
