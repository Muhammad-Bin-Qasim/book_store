import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_constants.dart';

/// A consistently styled, resilient book-cover thumbnail.
class BookThumb extends StatelessWidget {
  const BookThumb({
    required this.url,
    this.width = 72,
    this.height = 96,
    this.borderRadius = AppRadii.md,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String url;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.trim().isEmpty
            ? _fallback(scheme, Icons.menu_book_rounded)
            : CachedNetworkImage(
                imageUrl: url,
                fit: fit,
                placeholder: (context, url) => _fallback(
                  scheme,
                  Icons.menu_book_rounded,
                ),
                errorWidget: (context, url, error) => _fallback(
                  scheme,
                  Icons.broken_image_outlined,
                ),
              ),
      ),
    );
  }

  Widget _fallback(ColorScheme scheme, IconData icon) => ColoredBox(
    color: scheme.surfaceContainerHighest,
    child: Center(
      child: Icon(icon, color: scheme.onSurfaceVariant, size: 24),
    ),
  );
}
