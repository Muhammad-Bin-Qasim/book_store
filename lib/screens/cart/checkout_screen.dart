import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/motion.dart';
import '../../core/app_routes.dart';
import '../../core/app_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/book_thumb.dart';
import '../../widgets/design_system.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _addresses = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _paymentMethods = const <Map<String, dynamic>>[];
  String? _selectedAddressId;
  String _selectedPaymentId = _cashOnDeliveryId;
  bool _loadingProfile = true;
  bool _placingOrder = false;
  String? _profileError;

  static const String _cashOnDeliveryId = '__cash_on_delivery__';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({String? preferredAddressId}) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await _profileService.loadProfile(user.uid);
      if (!mounted) return;
      final defaultAddress = profile.addresses.where(
        (address) => address['isDefault'] == true,
      );
      final defaultPayment = profile.paymentMethods.where(
        (method) => method['isDefault'] == true,
      );
      setState(() {
        _addresses = profile.addresses;
        _paymentMethods = profile.paymentMethods;
        _selectedAddressId = _addresses.any((address) => address['id'] == preferredAddressId)
            ? preferredAddressId
            : defaultAddress.isNotEmpty
                ? defaultAddress.first['id'] as String?
                : _addresses.isNotEmpty
                    ? _addresses.first['id'] as String?
                    : null;
        _selectedPaymentId = defaultPayment.isNotEmpty
            ? _methodId(
                defaultPayment.first,
                profile.paymentMethods.indexOf(defaultPayment.first),
              )
            : _cashOnDeliveryId;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _profileError = ProfileService.friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _addAddress() async {
    final result = await context.pushNamed<dynamic>(
      AppRoutes.profileName,
      queryParameters: <String, String>{AppRoutes.profileAddressQuery: 'true'},
    );
    if (!mounted) return;
    final addressId = result is Map ? result['id'] as String? : null;
    await _loadProfile(preferredAddressId: addressId);
  }

  Future<void> _placeOrder() async {
    if (_placingOrder) return;
    final address = _selectedAddress;
    if (address == null) {
      _showMessage(AppStrings.checkoutNoAddress);
      return;
    }
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      _showMessage(AppStrings.checkoutNoItems);
      return;
    }
    setState(() => _placingOrder = true);
    try {
      final result = await context.read<OrderProvider>().placeOrder(
        shippingAddress: Map<String, dynamic>.from(address),
        paymentMethod: _selectedPayment,
      );
      if (!mounted) return;
      final orderId = result.orderId;
      if (orderId == null || result.estimatedDelivery == null) {
        _showMessage(AppStrings.checkoutUnavailableItems);
        return;
      }
      HapticFeedback.mediumImpact();
      context.goNamed(
        AppRoutes.orderConfirmationName,
        extra: OrderConfirmationArgs(
          orderId: orderId,
          totalPrice: result.totalPrice,
          estimatedDelivery: result.estimatedDelivery!,
          unavailableItemCount: result.unavailableBookIds.length,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        ErrorHandler.message(
          error,
          fallback: context.read<OrderProvider>().errorMessage ?? AppStrings.orderOperationFailed,
        ),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Map<String, dynamic>? get _selectedAddress {
    for (final address in _addresses) {
      if (address['id'] == _selectedAddressId) return address;
    }
    return null;
  }

  Map<String, dynamic> get _selectedPayment {
    if (_selectedPaymentId == _cashOnDeliveryId) {
      return <String, dynamic>{'type': AppStrings.cashOnDelivery, 'last4': ''};
    }
    for (var index = 0; index < _paymentMethods.length; index++) {
      final method = _paymentMethods[index];
      if (_methodId(method, index) == _selectedPaymentId) return method;
    }
    return <String, dynamic>{'type': AppStrings.cashOnDelivery, 'last4': ''};
  }

  String _methodId(Map<String, dynamic> method, int index) =>
      method['id'] as String? ?? 'saved-payment-$index';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final providerBusy = context.watch<OrderProvider>().isPlacingOrder;
    final busy = _placingOrder || providerBusy;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: _loadingProfile || cart.isLoading
          ? const LoadingIndicator()
          : cart.errorMessage != null
              ? ErrorView(
                  title: AppStrings.checkoutLoadFailed,
                  message: cart.errorMessage,
                  onRetry: cart.retry,
                )
              : _profileError != null
                  ? ErrorView(
                      title: AppStrings.checkoutLoadFailed,
                      message: _profileError,
                      onRetry: () => _loadProfile(),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          children: [
                            Card(
                              elevation: 1.1,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: StepTimeline(
                                  steps: const [
                                    AppStrings.checkoutStepAddress,
                                    AppStrings.checkoutStepPayment,
                                    AppStrings.checkoutStepReview,
                                  ],
                                  currentStep: _selectedAddressId == null ? 0 : 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CheckoutSection(
                              title: AppStrings.orderSummary,
                              child: Column(
                                children: [
                                  if (cart.items.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                      child: Text(AppStrings.checkoutNoItems),
                                    )
                                  else
                                    ...cart.items.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                        child: Row(
                                          children: [
                                            BookThumb(
                                              url: item.coverUrl,
                                              width: 42,
                                              height: 56,
                                              borderRadius: AppRadii.sm,
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.titleSmall,
                                                  ),
                                                  Text(
                                                    '${AppStrings.quantity}: ${item.quantity}',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.xs),
                                            Text(
                                              item.unavailable
                                                  ? AppStrings.unavailableLineTotal
                                                  : AppUtils.formatPrice(item.price * item.quantity),
                                              style: item.unavailable
                                                  ? Theme.of(context).textTheme.bodySmall
                                                  : AppUtils.priceTextStyle(
                                                      baseStyle: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const Divider(height: AppSpacing.lg),
                                  _SummaryLine(
                                    label: AppStrings.itemCount,
                                    value: '${cart.itemCount}',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _SummaryLine(
                                    label: AppStrings.total,
                                    value: AppUtils.formatPrice(cart.total),
                                    emphasize: true,
                                    isPrice: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CheckoutSection(
                              title: AppStrings.selectShippingAddress,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_addresses.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: Text(
                                        AppStrings.checkoutNoAddress,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    )
                                  else
                                    AbsorbPointer(
                                      absorbing: busy,
                                      child: Column(
                                        children: _addresses.map((address) {
                                          final id = address['id'] as String? ?? '';
                                          final selected = id == _selectedAddressId;
                                          final label = address['label'] as String? ?? AppStrings.shippingAddress;
                                          final name = address['fullName'] as String? ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                            child: _SelectableCard(
                                              selected: selected,
                                              title: '$label · $name',
                                              subtitle: _addressText(address),
                                              icon: Icons.location_on_outlined,
                                              isDefault: address['isDefault'] == true,
                                              onTap: () => setState(() => _selectedAddressId = id),
                                            ),
                                          );
                                        }).toList(growable: false),
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: busy ? null : _addAddress,
                                      icon: const Icon(Icons.add_location_alt_outlined),
                                      label: const Text(AppStrings.addNewAddress),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _CheckoutSection(
                              title: AppStrings.selectPaymentMethod,
                              child: Column(
                                children: [
                                  AbsorbPointer(
                                    absorbing: busy,
                                    child: Column(
                                      children: [
                                        _SelectableCard(
                                          selected: _selectedPaymentId == _cashOnDeliveryId,
                                          title: AppStrings.cashOnDelivery,
                                          subtitle: AppStrings.checkoutDemoNote,
                                          icon: Icons.payments_outlined,
                                          onTap: () => setState(() => _selectedPaymentId = _cashOnDeliveryId),
                                        ),
                                        ..._paymentMethods.asMap().entries.map((entry) {
                                          final method = entry.value;
                                          final id = _methodId(method, entry.key);
                                          final type = method['type'] as String? ?? AppStrings.card;
                                          final last4 = method['last4'] as String? ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                                            child: _SelectableCard(
                                              selected: _selectedPaymentId == id,
                                              title: type,
                                              subtitle: type == AppStrings.card && last4.isNotEmpty
                                                  ? '${AppStrings.paymentCardEnding} $last4'
                                                  : AppStrings.paymentMethodType,
                                              icon: type == AppStrings.card
                                                  ? Icons.credit_card_rounded
                                                  : Icons.account_balance_wallet_outlined,
                                              cardDigits: type == AppStrings.card && last4.isNotEmpty ? last4 : null,
                                              isDefault: method['isDefault'] == true,
                                              onTap: () => setState(() => _selectedPaymentId = id),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      AppStrings.paymentDemoNotice,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
      bottomNavigationBar: _loadingProfile || cart.errorMessage != null || _profileError != null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
                child: GlassBar(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: GradientButton(
                      label: AppStrings.checkoutPlaceOrder,
                      icon: Icons.lock_outline_rounded,
                      isLoading: busy,
                      onPressed: busy || _addresses.isEmpty || cart.items.isEmpty
                          ? null
                          : _placeOrder,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _addressText(Map<String, dynamic> address) => <String>[
    '${address['addressLine'] ?? ''}',
    '${address['city'] ?? ''} ${address['postalCode'] ?? ''}'.trim(),
    '${address['phone'] ?? ''}',
  ].where((part) => part.trim().isNotEmpty).join('\n');
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDefault = false,
    this.cardDigits,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDefault;
  final String? cardDigits;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.quick),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: .55)
                : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: .09),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: cardDigits == null ? null : MidnightGradients.indigo,
                  color: cardDigits == null ? scheme.surfaceContainerHighest : null,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  icon,
                  color: cardDigits == null ? scheme.primary : Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isDefault)
                          const StatusChip(label: AppStrings.defaultLabel),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      cardDigits == null
                          ? subtitle
                          : '$subtitle · ${AppStrings.maskedCardDigits} $cardDigits',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.quick),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: scheme.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1.1,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isPrice = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool isPrice;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isPrice ? AppUtils.priceTextStyle(baseStyle: style) : style,
          ),
        ),
      ],
    );
  }
}
