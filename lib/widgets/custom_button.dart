import 'package:flutter/material.dart';

import 'design_system.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => GradientButton(
    label: label,
    onPressed: onPressed,
    isLoading: isLoading,
    icon: icon,
  );
}
