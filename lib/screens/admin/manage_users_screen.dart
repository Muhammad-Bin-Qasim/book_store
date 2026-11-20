import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_utils.dart';
import '../../core/utils/error_handler.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/initials_avatar.dart';
import 'admin_scaffold.dart';
import 'admin_ui.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _search = '';

  Future<void> _refresh() async {
    try {
      await context.read<AdminProvider>().refresh();
    } catch (_) {
      // The provider exposes the user-list error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final actorUid = context.watch<AuthProvider>().currentUser?.uid ?? '';
    return AdminScaffold(
      title: AppStrings.manageUsers,
      selectedIndex: 3,
      child: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final query = _search.trim().toLowerCase();
          final users = admin.users
              .where(
                (user) =>
                    user.name.toLowerCase().contains(query) ||
                    user.email.toLowerCase().contains(query),
              )
              .toList(growable: false);
          if (admin.errorMessage != null && !admin.hasLoaded) {
            return AdminErrorView(
              message: admin.errorMessage!,
              onRetry: _refresh,
            );
          }
          if (admin.isLoading && !admin.hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: <Widget>[
                    SizedBox(
                      width: wide ? 420 : constraints.maxWidth,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: AppStrings.searchUsers,
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (value) => setState(() => _search = value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (users.isEmpty)
                      SizedBox(
                        height: 220,
                        child: Center(child: Text(AppStrings.noUsersFound)),
                      )
                    else if (wide)
                      _UsersTable(users: users, actorUid: actorUid)
                    else
                      ...users.map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Card(
                            elevation: 1.2,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _showDetails(user.uid, actorUid),
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    InitialsAvatar(
                                      name: user.name.isEmpty ? AppStrings.accountNameUnavailable : user.name,
                                      size: 48,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name.isEmpty ? AppStrings.accountNameUnavailable : user.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            user.email,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Wrap(
                                            spacing: AppSpacing.xs,
                                            runSpacing: AppSpacing.xs,
                                            children: [
                                              _UserInfoChip(
                                                label: _roleLabel(user.role),
                                                icon: user.role == UserRole.admin ? Icons.admin_panel_settings_outlined : Icons.person_outline_rounded,
                                                background: Theme.of(context).colorScheme.primaryContainer,
                                                foreground: Theme.of(context).colorScheme.onPrimaryContainer,
                                              ),
                                              _UserInfoChip(
                                                label: user.disabled ? AppStrings.accountDisabled : AppStrings.accountEnabled,
                                                icon: user.disabled ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                                background: user.disabled
                                                    ? Theme.of(context).colorScheme.errorContainer
                                                    : Theme.of(context).colorScheme.secondaryContainer,
                                                foreground: user.disabled
                                                    ? Theme.of(context).colorScheme.onErrorContainer
                                                    : Theme.of(context).colorScheme.onSecondaryContainer,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetails(String uid, String actorUid) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => _UserDetailsDialog(uid: uid, actorUid: actorUid),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.actorUid});
  final List<AppUser> users;
  final String actorUid;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1.2,
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text(AppStrings.fullName)),
          DataColumn(label: Text(AppStrings.email)),
          DataColumn(label: Text(AppStrings.role)),
          DataColumn(label: Text(AppStrings.joinedDate)),
          DataColumn(label: Text(AppStrings.accountDisabled)),
          DataColumn(label: Text(AppStrings.userDetails)),
        ],
        rows: users
            .map(
              (user) => DataRow(
                onSelectChanged:
                    (_) => showDialog<void>(
                      context: context,
                      builder:
                          (dialogContext) => _UserDetailsDialog(
                            uid: user.uid,
                            actorUid: actorUid,
                          ),
                    ),
                cells: <DataCell>[
                  DataCell(
                    Text(
                      user.name.isEmpty
                          ? AppStrings.accountNameUnavailable
                          : user.name,
                    ),
                  ),
                  DataCell(Text(user.email)),
                  DataCell(_UserInfoChip(
                    label: _roleLabel(user.role),
                    icon: user.role == UserRole.admin ? Icons.admin_panel_settings_outlined : Icons.person_outline_rounded,
                    background: Theme.of(context).colorScheme.primaryContainer,
                    foreground: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
                  DataCell(
                    Text(
                      user.createdAt == null
                          ? AppStrings.noData
                          : DateFormat.yMMMd().format(user.createdAt!),
                    ),
                  ),
                  DataCell(_UserInfoChip(
                    label: user.disabled ? AppStrings.accountDisabled : AppStrings.accountEnabled,
                    icon: user.disabled ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                    background: user.disabled
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                    foreground: user.disabled
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  )),
                  DataCell(
                    IconButton(
                      tooltip: AppStrings.userDetails,
                      onPressed:
                          () => showDialog<void>(
                            context: context,
                            builder:
                                (dialogContext) => _UserDetailsDialog(
                                  uid: user.uid,
                                  actorUid: actorUid,
                                ),
                          ),
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    ),
  );
}

String _roleLabel(UserRole role) =>
    role == UserRole.admin ? AppStrings.adminRole : AppStrings.userRole;

class _UserDetailsDialog extends StatelessWidget {
  const _UserDetailsDialog({required this.uid, required this.actorUid});
  final String uid;
  final String actorUid;

  @override
  Widget build(BuildContext context) => Consumer<AdminProvider>(
    builder: (context, admin, _) {
      final user = admin.userById(uid);
      if (user == null) {
        return AlertDialog(
          title: const Text(AppStrings.userDetails),
          content: const Text(AppStrings.profileNotFound),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.closeLabel),
            ),
          ],
        );
      }
      final orders =
          admin.orders.where((order) => order.userId == uid).toList();
      final totalSpent = orders
          .where((order) => order.status != OrderStatus.cancelled)
          .fold<double>(0, (sum, order) => sum + order.totalPrice);
      return AlertDialog(
        title: Text(
          user.name.isEmpty ? AppStrings.accountNameUnavailable : user.name,
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(user.email),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${AppStrings.joinedDate}: ${user.createdAt == null ? AppStrings.noData : DateFormat.yMMMd().format(user.createdAt!)}',
                ),
                Text('${AppStrings.orderCount}: ${orders.length}'),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${AppStrings.totalSpent}: '),
                      TextSpan(
                        text: AppUtils.formatPrice(totalSpent),
                        style: AppUtils.priceTextStyle(),
                      ),
                    ],
                  ),
                ),
                Text('${AppStrings.addressBook}: ${user.addresses.length}'),
                Text(
                  '${AppStrings.paymentMethods}: ${user.paymentMethods.length}',
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<UserRole>(
                  key: ValueKey<UserRole>(user.role),
                  initialValue: user.role,
                  decoration: const InputDecoration(labelText: AppStrings.role),
                  items: UserRole.values
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(_roleLabel(role)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged:
                      actorUid == user.uid
                          ? null
                          : (role) {
                            if (role != null && role != user.role) {
                              _changeRole(context, user, role);
                            }
                          },
                ),
                if (actorUid == user.uid)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      AppStrings.selfRoleChangeBlocked,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    user.disabled
                        ? AppStrings.enableAccount
                        : AppStrings.disableAccount,
                  ),
                  value: user.disabled,
                  onChanged:
                      actorUid == user.uid
                          ? null
                          : (value) => _setDisabled(context, user, value),
                ),
                Text(
                  AppStrings.appLevelDisableNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.closeLabel),
          ),
        ],
      );
    },
  );

  Future<void> _changeRole(
    BuildContext context,
    AppUser user,
    UserRole role,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text(AppStrings.roleChangeConfirmation),
                content: Text('${user.name} · ${_roleLabel(role)}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(AppStrings.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text(AppStrings.changeRole),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<AdminProvider>().updateUserRole(
        target: user,
        role: role,
        actorUid: actorUid,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.userUpdated)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(
              error,
              fallback: AppStrings.adminOperationFailed,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _setDisabled(
    BuildContext context,
    AppUser user,
    bool disabled,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(
                  disabled
                      ? AppStrings.disableAccountConfirmation
                      : AppStrings.enableAccountConfirmation,
                ),
                content: const Text(AppStrings.appLevelDisableNote),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text(AppStrings.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      disabled
                          ? AppStrings.disableAccount
                          : AppStrings.enableAccount,
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<AdminProvider>().setUserDisabled(
        target: user,
        disabled: disabled,
        actorUid: actorUid,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.userUpdated)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.message(
              error,
              fallback: AppStrings.adminOperationFailed,
            ),
          ),
        ),
      );
    }
  }
}


class _UserInfoChip extends StatelessWidget {
  const _UserInfoChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
