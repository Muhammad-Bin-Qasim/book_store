import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/motion.dart';

/// A short entrance animation that plays once for each stable item ID.
///
/// [playedItemIds] belongs to the scrolling screen, so an item won't replay
/// after it leaves and re-enters the list's cache area.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    required this.child,
    required this.itemId,
    required this.index,
    required this.playedItemIds,
    super.key,
  });

  final Widget child;
  final String itemId;
  final int index;
  final Set<String> playedItemIds;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate =
        !reduceMotion(context) && index < 10 && playedItemIds.add(itemId);
    if (!shouldAnimate) {
      playedItemIds.add(itemId);
      return child;
    }

    return child
        .animate(
          delay: Duration(milliseconds: index * 40),
          autoPlay: true,
        )
        .fadeIn(
          duration: AppMotion.standard,
          curve: AppMotion.enterCurve,
        )
        .slideY(
          begin: .055,
          end: 0,
          duration: AppMotion.standard,
          curve: AppMotion.enterCurve,
        );
  }
}
