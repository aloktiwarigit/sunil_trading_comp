// =============================================================================
// RoleGate — S4.2: role-based UI gating for the shopkeeper ops app.
//
// Wraps any widget and shows/hides it based on the current operator's
// permissions. Uses the Operator from OpsAuthState.
//
// AC #2: UI rendered conditionally based on role.
//   - bhaiya: full access
//   - beta: inventory, orders, chat, curation; no operator management/theme
//   - munshi: orders read-only, udhaar, payments; no inventory, no chat
// AC edge #3: role changes mid-session → refreshes on next screen mount.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'auth_controller.dart';

/// Current operator provider — derived from auth state.
/// Returns null if not signed in or not authorized.
final currentOperatorProvider = Provider<Operator?>((ref) {
  final authAsync = ref.watch(opsAuthControllerProvider);
  return authAsync.valueOrNull?.operator;
});

/// Whether the current operator has a specific permission.
/// Returns false if not signed in.
bool hasPermission(Operator? op, OperatorPermission permission) {
  if (op == null) return false;
  return switch (permission) {
    OperatorPermission.editInventory => op.permissions.canEditInventory,
    OperatorPermission.approveDiscounts => op.permissions.canApproveDiscounts,
    OperatorPermission.recordUdhaar => op.permissions.canRecordUdhaar,
    OperatorPermission.deleteOrders => op.permissions.canDeleteOrders,
    OperatorPermission.manageOperators => op.permissions.canManageOperators,
  };
}

/// Permission enum for type-safe gating.
enum OperatorPermission {
  editInventory,
  approveDiscounts,
  recordUdhaar,
  deleteOrders,
  manageOperators,
}

/// Widget that shows its child only if the current operator has the
/// required permission. Shows [fallback] (or nothing) otherwise.
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final OperatorPermission permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final op = ref.watch(currentOperatorProvider);
    if (hasPermission(op, permission)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows its child only if the current operator has
/// the bhaiya role. Used for bhaiya-exclusive screens.
class BhaiyaOnlyGate extends ConsumerWidget {
  const BhaiyaOnlyGate({
    super.key,
    required this.child,
    this.fallback,
  });

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final op = ref.watch(currentOperatorProvider);
    if (op?.isBhaiya == true) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows its child only if the current operator's role
/// is in the allowed set.
class RoleSetGate extends ConsumerWidget {
  const RoleSetGate({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  final Set<OperatorRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final op = ref.watch(currentOperatorProvider);
    if (op != null && allowedRoles.contains(op.role)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
