import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../core/motion.dart';
import '../../widgets/design_system.dart';

class OrderConfirmationArgs {
  const OrderConfirmationArgs({
    required this.orderId,
    required this.totalPrice,
    required this.estimatedDelivery,
    this.unavailableItemCount = 0,
  });

  final String orderId;
  final double totalPrice;
  final DateTime estimatedDelivery;
  final int unavailableItemCount;
}

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({required this.args, super.key});

  final OrderConfirmationArgs? args;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.emphasis);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller
        ..stop()
        ..value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.args;
    final theme = Theme.of(context);
    if (details == null) {
      return const Scaffold(
        body: Center(child: Text(AppStrings.orderIdUnavailable)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.orderPlacedTitle),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final progress = Curves.easeOutCubic.transform(
                            _controller.value,
                          );
                          final scale = .68 + .32 * progress;
                          return SizedBox(
                            width: 148,
                            height: 148,
                            child: CustomPaint(
                              painter: _ConfirmationParticlesPainter(
                                progress: progress,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                  theme.colorScheme.tertiary,
                                  AppColors.amber,
                                ],
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale: scale,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 104,
                                        height: 104,
                                        decoration: const BoxDecoration(
                                          gradient: MidnightGradients.forest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 58,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.orderPlacedTitle,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.orderPlacedMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ConfirmationLine(
                      label: AppStrings.orderNumber,
                      value: details.orderId,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ConfirmationLine(
                      label: AppStrings.total,
                      value: AppUtils.formatPrice(details.totalPrice),
                      isPrice: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ConfirmationLine(
                      label: AppStrings.estimatedDelivery,
                      value: DateFormat.yMMMd().format(
                        details.estimatedDelivery,
                      ),
                    ),
                    if (details.unavailableItemCount > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppStrings.checkoutUnavailableItems,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.goNamed(
                          AppRoutes.orderDetailsName,
                          pathParameters: <String, String>{'id': details.orderId},
                        ),
                        child: const Text(AppStrings.viewOrder),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.goNamed(AppRoutes.homeName),
                        child: const Text(AppStrings.continueShopping),
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

class _ConfirmationParticlesPainter extends CustomPainter {
  const _ConfirmationParticlesPainter({
    required this.progress,
    required this.colors,
  });

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringProgress = Curves.easeOutCubic.transform(progress);
    final ringRadius = 38 + ringProgress * 36;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = colors.first.withValues(alpha: (1 - ringProgress) * .56);
    canvas.drawCircle(center, ringRadius, ringPaint);

    final particleProgress = Curves.easeOutCubic.transform(progress);
    for (var index = 0; index < 20; index++) {
      final angle = (math.pi * 2 * index / 20) + (index.isEven ? .08 : -.08);
      final startRadius = 48 + (index % 3) * 3;
      final distance = 13 + (index % 4) * 3;
      final radius = startRadius + distance * particleProgress;
      final point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final opacity =
          ((1 - particleProgress) * .95).clamp(0.0, 1.0).toDouble();
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final particleSize = 2.2 + (index % 3) * .55;
      if (index.isEven) {
        canvas.drawCircle(point, particleSize, paint);
      } else {
        final rect = Rect.fromCenter(
          center: point,
          width: particleSize * 1.5,
          height: particleSize * .75,
        );
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.shift(Offset(-point.dx, -point.dy)),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfirmationParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class _ConfirmationLine extends StatelessWidget {
  const _ConfirmationLine({
    required this.label,
    required this.value,
    this.isPrice = false,
  });

  final String label;
  final String value;
  final bool isPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isPrice ? AppUtils.priceTextStyle() : null,
          ),
        ),
      ],
    );
  }
}
