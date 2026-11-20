import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_routes.dart';
import '../../core/theme_controller.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/design_system.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.openAddressFormOnLoad = false});

  final bool openAddressFormOnLoad;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _addresses = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _paymentMethods = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  String get _uid => context.read<AuthProvider>().currentUser!.uid;
  bool _addressFormRequested = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
    _addressFormRequested = widget.openAddressFormOnLoad;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openAddressFormOnLoad && !oldWidget.openAddressFormOnLoad) {
      _addressFormRequested = true;
      if (!_isLoading) unawaited(_openAddressFormWhenReady());
    }
  }

  Future<void> _openAddressFormWhenReady() async {
    while (_isLoading && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted || !_addressFormRequested) return;
    _addressFormRequested = false;
    await _addOrEditAddress();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _profileService.loadProfile(_uid);
      if (!mounted) return;
      setState(() {
        _addresses = data.addresses;
        _paymentMethods = data.paymentMethods;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = ProfileService.friendlyMessage(error);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted && _loadError == null && _addressFormRequested) {
      unawaited(_openAddressFormWhenReady());
    }
  }

  Future<bool> _runProfileMutation(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isSaving = true);
    try {
      await action();
      final data = await _profileService.loadProfile(_uid);
      if (!mounted) return false;
      setState(() {
        _addresses = data.addresses;
        _paymentMethods = data.paymentMethods;
      });
      _showSnackBar(successMessage);
      return true;
    } catch (error) {
      if (!mounted) return false;
      _showSnackBar(ProfileService.friendlyMessage(error));
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editName(String currentName) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _NameDialog(initialName: currentName),
    );
    if (name == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.updateDisplayName(name);
    if (!mounted) return;
    if (succeeded) {
      _showSnackBar(AppStrings.nameUpdated);
    } else {
      _showSnackBar(auth.errorMessage ?? AppStrings.profileSaveFailed);
      auth.clearError();
    }
  }

  Future<void> _addOrEditAddress([Map<String, dynamic>? existing]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddressDialog(initialValue: existing),
    );
    if (result == null || !mounted) return;
    final id = existing?['id'] as String? ?? _profileService.createId();
    final address = <String, dynamic>{
      ...result,
      'id': id,
      'isDefault': existing?['isDefault'] == true || _addresses.isEmpty,
    };
    final saved = await _runProfileMutation(
      () => _profileService.saveAddress(_uid, address),
      AppStrings.addressSaved,
    );
    if (saved && widget.openAddressFormOnLoad && mounted) {
      context.pop(<String, dynamic>{...address, 'id': id});
    }
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    if (!await _confirmDelete() || !mounted) return;
    await _runProfileMutation(
      () => _profileService.deleteAddress(_uid, address['id'] as String),
      AppStrings.addressDeleted,
    );
  }

  Future<void> _makeAddressDefault(Map<String, dynamic> address) async {
    await _runProfileMutation(
      () => _profileService.setDefaultAddress(_uid, address['id'] as String),
      AppStrings.defaultAddressUpdated,
    );
  }

  Future<void> _addPaymentMethod() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _PaymentMethodDialog(),
    );
    if (result == null || !mounted) return;
    final method = <String, dynamic>{
      ...result,
      'id': _profileService.createId(),
      'isDefault': _paymentMethods.isEmpty,
    };
    await _runProfileMutation(
      () => _profileService.savePaymentMethod(_uid, method),
      AppStrings.paymentMethodAdded,
    );
  }

  Future<void> _deletePaymentMethod(Map<String, dynamic> method) async {
    if (!await _confirmDelete() || !mounted) return;
    await _runProfileMutation(
      () => _profileService.deletePaymentMethod(_uid, method['id'] as String),
      AppStrings.paymentMethodDeleted,
    );
  }

  Future<void> _makePaymentDefault(Map<String, dynamic> method) async {
    await _runProfileMutation(
      () =>
          _profileService.setDefaultPaymentMethod(_uid, method['id'] as String),
      AppStrings.paymentMethodDefaultUpdated,
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(AppStrings.deleteConfirmationTitle),
            content: const Text(AppStrings.deleteConfirmationMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(AppStrings.remove),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmationTitle),
        content: const Text(AppStrings.logoutConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.logout();
    if (!mounted) return;
    if (succeeded) {
      context.goNamed(AppRoutes.loginName);
    } else {
      _showSnackBar(auth.errorMessage ?? AppStrings.authGenericError);
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeController = context.watch<ThemeController>();
    final user = auth.currentUser;
    final isBusy = _isSaving || auth.isLoading;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: _isLoading
          ? const LoadingIndicator()
          : _loadError != null
          ? ErrorView(
              title: AppStrings.profileLoadFailed,
              message: _loadError!,
              onRetry: () {
                setState(() => _isLoading = true);
                unawaited(_loadProfile());
              },
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (isBusy) const LinearProgressIndicator(),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: MidnightGradients.forest,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: .16),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.onDarkAccent.withValues(
                          alpha: .16,
                        ),
                        child: Text(
                          _initials(user?.name ?? ''),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.onDarkAccent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user?.name.isNotEmpty == true
                            ? user!.name
                            : AppStrings.accountNameUnavailable,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onDarkAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onDarkAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _editName(user?.name ?? ''),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onDarkAccent,
                          side: BorderSide(
                            color: AppColors.onDarkAccent.withValues(
                              alpha: .78,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(AppStrings.editProfile),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _sectionHeader(
                  context,
                  AppStrings.addressBook,
                  Icons.location_on_outlined,
                  AppStrings.addAddress,
                  isBusy ? null : () => _addOrEditAddress(),
                ),
                if (_addresses.isEmpty)
                  _emptySection(context, AppStrings.addressBook)
                else
                  ..._addresses.map(
                    (address) => _AddressCard(
                      address: address,
                      saving: isBusy,
                      onEdit: () => _addOrEditAddress(address),
                      onDelete: () => _deleteAddress(address),
                      onSetDefault: () => _makeAddressDefault(address),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                _sectionHeader(
                  context,
                  AppStrings.paymentMethods,
                  Icons.payment_outlined,
                  AppStrings.addPaymentMethod,
                  isBusy ? null : _addPaymentMethod,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    AppStrings.paymentDemoNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_paymentMethods.isEmpty)
                  _emptySection(context, AppStrings.paymentMethods)
                else
                  ..._paymentMethods.map(
                    (method) => _PaymentMethodCard(
                      method: method,
                      saving: isBusy,
                      onDelete: () => _deletePaymentMethod(method),
                      onSetDefault: () => _makePaymentDefault(method),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text(AppStrings.appearance),
                          subtitle: const Text(
                            AppStrings.appearanceDescription,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedButton<AppThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<AppThemeMode>(
                              value: AppThemeMode.system,
                              label: Text(AppStrings.themeSystem),
                            ),
                            ButtonSegment<AppThemeMode>(
                              value: AppThemeMode.light,
                              label: Text(AppStrings.themeLight),
                            ),
                            ButtonSegment<AppThemeMode>(
                              value: AppThemeMode.dark,
                              label: Text(AppStrings.themeDark),
                            ),
                          ],
                          selected: {themeController.mode},
                          onSelectionChanged: (selection) {
                            unawaited(themeController.setMode(selection.first));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.favorite_border_rounded),
                        title: const Text(AppStrings.wishlist),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pushNamed(AppRoutes.wishlistName),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_rounded),
                        title: const Text(AppStrings.orders),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pushNamed(AppRoutes.ordersName),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: AppStrings.logout,
                  icon: Icons.logout_rounded,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _confirmLogout,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String actionLabel,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _emptySection(BuildContext context, String section) => Card(
    child: ListTile(
      leading: const Icon(Icons.info_outline_rounded),
      title: Text(section),
      subtitle: const Text(AppStrings.noSavedDetails),
    ),
  );

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final values = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return values.isEmpty ? AppStrings.initialsFallback : values;
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.saving,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });
  final Map<String, dynamic> address;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDefault = address['isDefault'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${address['label'] ?? ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isDefault) const Chip(label: Text(AppStrings.defaultLabel)),
                IconButton(
                  tooltip: AppStrings.editAddress,
                  onPressed: saving ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: AppStrings.deleteAddress,
                  onPressed: saving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text('${address['fullName'] ?? ''}'),
            Text('${address['phone'] ?? ''}'),
            Text('${address['addressLine'] ?? ''}'),
            Text('${address['city'] ?? ''} ${address['postalCode'] ?? ''}'),
            if (!isDefault)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: saving ? null : onSetDefault,
                  child: const Text(AppStrings.setAsDefault),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.saving,
    required this.onDelete,
    required this.onSetDefault,
  });
  final Map<String, dynamic> method;
  final bool saving;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = method['type'] as String? ?? AppStrings.cashOnDelivery;
    final isCard = type == AppStrings.card;
    final isDefault = method['isDefault'] == true;
    final subtitle = isCard
        ? '${method['holderName'] ?? ''} ${AppStrings.maskedCardDigits} ${method['last4'] ?? ''}  ${method['expiry'] ?? ''}'
        : AppStrings.paymentDemoNotice;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isCard ? Icons.credit_card_rounded : Icons.payments_outlined,
            ),
            title: Row(
              children: [
                Expanded(child: Text(type)),
                if (isDefault) const Chip(label: Text(AppStrings.defaultLabel)),
              ],
            ),
            subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
            trailing: IconButton(
              tooltip: AppStrings.deletePaymentMethod,
              onPressed: saving ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
          if (!isDefault)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: TextButton(
                  onPressed: saving ? null : onSetDefault,
                  child: const Text(AppStrings.setAsDefault),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initialName});
  final String initialName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(AppStrings.editName),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: AppStrings.fullName),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppStrings.fullNameValidation
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() != true) return;
          Navigator.of(context).pop(_controller.text.trim());
        },
        child: const Text(AppStrings.save),
      ),
    ],
  );
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({this.initialValue});
  final Map<String, dynamic>? initialValue;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late String _label;

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue ?? <String, dynamic>{};
    _name = TextEditingController(text: value['fullName'] as String? ?? '');
    _phone = TextEditingController(text: value['phone'] as String? ?? '');
    _line = TextEditingController(text: value['addressLine'] as String? ?? '');
    _city = TextEditingController(text: value['city'] as String? ?? '');
    _postal = TextEditingController(text: value['postalCode'] as String? ?? '');
    _label = value['label'] as String? ?? AppStrings.homeAddress;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line.dispose();
    _city.dispose();
    _postal.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? AppStrings.requiredField : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialValue == null
          ? AppStrings.addAddress
          : AppStrings.editAddress,
    ),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _label,
                decoration: const InputDecoration(labelText: AppStrings.label),
                items: const [
                  DropdownMenuItem(
                    value: AppStrings.homeAddress,
                    child: Text(AppStrings.homeAddress),
                  ),
                  DropdownMenuItem(
                    value: AppStrings.workAddress,
                    child: Text(AppStrings.workAddress),
                  ),
                  DropdownMenuItem(
                    value: AppStrings.otherAddress,
                    child: Text(AppStrings.otherAddress),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _label = value ?? AppStrings.homeAddress),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: AppStrings.fullName,
                ),
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: AppStrings.phone),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_required(value) != null) return AppStrings.requiredField;
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length < 7 || digits.length > 15
                      ? AppStrings.addressValidationPhone
                      : null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _line,
                decoration: const InputDecoration(
                  labelText: AppStrings.addressLine,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: AppStrings.city),
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _postal,
                decoration: const InputDecoration(
                  labelText: AppStrings.postalCode,
                ),
                validator: (value) {
                  if (_required(value) != null) return AppStrings.requiredField;
                  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9 -]{2,11}$')
                          .hasMatch((value ?? '').trim())
                      ? null
                      : AppStrings.addressValidationPostal;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() != true) return;
          Navigator.of(context).pop(<String, dynamic>{
            'label': _label,
            'fullName': _name.text.trim(),
            'phone': _phone.text.trim(),
            'addressLine': _line.text.trim(),
            'city': _city.text.trim(),
            'postalCode': _postal.text.trim(),
          });
        },
        child: const Text(AppStrings.save),
      ),
    ],
  );
}

class _PaymentMethodDialog extends StatefulWidget {
  const _PaymentMethodDialog();

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _holder = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  String _type = AppStrings.card;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    super.dispose();
  }

  String? _validateExpiry(String? value) {
    final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$')
        .firstMatch((value ?? '').trim());
    if (match == null) return AppStrings.expiryValidation;
    final month = int.parse(match.group(1)!);
    var year = int.parse(match.group(2)!);
    if (year < 100) year += 2000;
    final expiryMonth = DateTime(year, month);
    final now = DateTime.now();
    if (expiryMonth.isBefore(DateTime(now.year, now.month))) {
      return AppStrings.expiryValidation;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(AppStrings.addPaymentMethod),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: AppStrings.paymentMethodType,
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppStrings.card,
                    child: Text(AppStrings.card),
                  ),
                  DropdownMenuItem(
                    value: AppStrings.cashOnDelivery,
                    child: Text(AppStrings.cashOnDelivery),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? AppStrings.card),
              ),
              if (_type == AppStrings.card) ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _holder,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: AppStrings.cardHolderName,
                  ),
                  validator: (value) =>
                      _type == AppStrings.card &&
                          (value == null || value.trim().isEmpty)
                      ? AppStrings.fullNameValidation
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _number,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: const InputDecoration(
                    labelText: AppStrings.cardNumber,
                  ),
                  validator: (value) =>
                      RegExp(r'^\d{16}$').hasMatch(value ?? '')
                      ? null
                      : AppStrings.cardNumberValidation,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _expiry,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: const InputDecoration(
                    labelText: AppStrings.expiryDate,
                  ),
                  validator: _validateExpiry,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.paymentDemoNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(AppStrings.cancel),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState?.validate() != true) return;
          final digits = _number.text;
          Navigator.of(context).pop(<String, dynamic>{
            'type': _type,
            'holderName': _type == AppStrings.card ? _holder.text.trim() : '',
            'last4': _type == AppStrings.card
                ? digits.substring(digits.length - 4)
                : '',
            'expiry': _type == AppStrings.card ? _expiry.text.trim() : '',
          });
        },
        child: const Text(AppStrings.save),
      ),
    ],
  );
}
