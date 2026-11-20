import 'package:flutter/material.dart';

/// Shared motion tokens for the Midnight Library design system.
class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration emphasis = Duration(milliseconds: 520);
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve emphasizedCurve = Curves.easeOutBack;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;
}

/// Convenience alias for callers that only need the accessibility preference.
bool reduceMotion(BuildContext context) => AppMotion.reduceMotion(context);
