import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/motion.dart';
import 'design_system.dart';

/// Compact animated quantity control shared by cart surfaces.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperAction(
            icon: Icons.remove_rounded,
            tooltip: AppStrings.decreaseQuantity,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
          ),
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.quick),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: SizedBox(
              key: ValueKey<int>(value),
              width: 28,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _StepperAction(
            icon: Icons.add_rounded,
            tooltip: AppStrings.increaseQuantity,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperAction extends StatelessWidget {
  const _StepperAction({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: PressScale(
        onTap: enabled ? onTap : null,
        child: SizedBox.square(
          dimension: 42,
          child: Icon(
            icon,
            size: 19,
            color: enabled ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: .45),
          ),
        ),
      ),
    );
  }
}
