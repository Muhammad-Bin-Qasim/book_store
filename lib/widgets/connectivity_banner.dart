import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import 'design_system.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnection,
      onError: (Object _) {},
    );
    unawaited(_checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (mounted) _updateConnection(results);
    } catch (_) {
      // Keep the last known state if the platform check is unavailable.
    }
  }

  void _updateConnection(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!mounted || hasConnection == _hasConnection) return;
    setState(() => _hasConnection = hasConnection);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_hasConnection)
          DecoratedBox(
            decoration: const BoxDecoration(gradient: MidnightGradients.alert),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: AppColors.onDarkAccent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        AppStrings.noInternetConnection,
                        style: TextStyle(
                          color: AppColors.onDarkAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
