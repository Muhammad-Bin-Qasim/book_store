import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../widgets/empty_state.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(icon: icon, title: title, message: message),
      ),
    );
  }
}
