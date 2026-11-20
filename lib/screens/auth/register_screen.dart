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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (succeeded) {
      context.goNamed(
        auth.isAdmin ? AppRoutes.adminDashboardName : AppRoutes.homeName,
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
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
                    title: AppStrings.registerHeading,
                    subtitle: AppStrings.registerMessage,
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    label: AppStrings.fullName,
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: AuthValidators.requiredValue,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: AppStrings.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: AppStrings.password,
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: AuthValidators.password,
                    suffixIcon: IconButton(
                      tooltip:
                          _passwordVisible
                              ? AppStrings.passwordVisibilityHide
                              : AppStrings.passwordVisibilityShow,
                      onPressed:
                          auth.isLoading
                              ? null
                              : () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    label: AppStrings.confirmPassword,
                    controller: _confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final requiredError = AuthValidators.requiredValue(value);
                      if (requiredError != null) return requiredError;
                      return value == _passwordController.text
                          ? null
                          : AppStrings.passwordMismatch;
                    },
                    suffixIcon: IconButton(
                      tooltip:
                          _confirmPasswordVisible
                              ? AppStrings.passwordVisibilityHide
                              : AppStrings.passwordVisibilityShow,
                      onPressed:
                          auth.isLoading
                              ? null
                              : () => setState(
                                () =>
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible,
                              ),
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: AppStrings.register,
                    onPressed: _register,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.goNamed(AppRoutes.loginName),
                    child: const Text(AppStrings.alreadyHaveAccount),
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
