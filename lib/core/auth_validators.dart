import 'app_constants.dart';

class AuthValidators {
  AuthValidators._();

  static String? requiredValue(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredValue(value);
    if (requiredError != null) return requiredError;
    final normalized = value!.trim();
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
    return valid ? null : AppStrings.invalidEmail;
  }

  static String? password(String? value) {
    final requiredError = requiredValue(value);
    if (requiredError != null) return requiredError;
    return value!.length >= 6 ? null : AppStrings.shortPassword;
  }
}
