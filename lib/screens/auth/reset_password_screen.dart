import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/auth_validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/design_system.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.resetPassword(
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    if (succeeded) {
      setState(() => _emailSent = true);
    } else {
      final message = auth.errorMessage ?? AppStrings.authGenericError;
      auth.clearError();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resetPassword)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AuthHero(
                    title: AppStrings.resetPasswordHeading,
                    subtitle: AppStrings.resetPasswordMessage,
                    icon: Icons.lock_reset_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    label: AppStrings.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: AppStrings.sendResetLink,
                    onPressed: _sendResetLink,
                    isLoading: auth.isLoading,
                  ),
                  if (_emailSent) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.resetEmailSent,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => context.goNamed(AppRoutes.loginName),
                    child: const Text(AppStrings.backToLogin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
