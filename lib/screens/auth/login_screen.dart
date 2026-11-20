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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (succeeded) {
      context.goNamed(
        auth.isAdmin ? AppRoutes.adminDashboardName : AppRoutes.homeName,
      );
    } else {
      _showError(auth);
    }
  }

  Future<void> _googleLogin() async {
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.googleLogin();
    if (!mounted) return;
    if (succeeded) {
      context.goNamed(
        auth.isAdmin ? AppRoutes.adminDashboardName : AppRoutes.homeName,
      );
    } else {
      _showError(auth);
    }
  }

  void _showError(AuthProvider auth) {
    final message = auth.errorMessage ?? AppStrings.authGenericError;
    auth.clearError();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.login)),
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
                    title: AppStrings.loginHeading,
                    subtitle: AppStrings.loginMessage,
                    icon: Icons.menu_book_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
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
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: AppStrings.login,
                    onPressed: _login,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _googleLogin,
                    icon:
                        auth.isLoading
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.account_circle_outlined),
                    label: const Text(AppStrings.continueWithGoogle),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed:
                          () => context.goNamed(AppRoutes.resetPasswordName),
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.goNamed(AppRoutes.registerName),
                    child: const Text(AppStrings.needAccount),
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
