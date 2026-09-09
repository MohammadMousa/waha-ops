import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/branch.dart';
import '../router/routes.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';
import '../widgets/app_nav_drawer.dart';

// PROCESS_INVENTORY is the permission required to run the visit workflow —
// granted to OPERATOR and BRANCH_ADMIN roles (not CASHIER, which only gets
// VIEW_INVENTORY). Resolved once at login and the same across every store
// the employee can access (see to_Frontend_AI_On_Inventory_Task [8],
// 2026-09-09) — so it's checked once here, not per store picked.
const _kProcessInventoryPermission = 'PROCESS_INVENTORY';

// Shown after login with the employee's own accessible stores (from
// POST /api/pos/auth/login's `stores` list — never auto-picked by the
// backend, see to_Frontend_AI_On_Inventory_Task [4]/[5]/[8]). An empty
// list is a valid, real state: the employee has no branch access.
// Picking a store is purely local now — there's no POST /api/pos/auth/store
// anymore, permissions already came back with login.
class StoreSelectScreen extends StatelessWidget {
  const StoreSelectScreen({super.key});

  void _select(BuildContext context, Branch store) {
    context.read<AuthState>().selectStore(store.id);
    Navigator.of(context).pushReplacementNamed(Routes.visitHome);
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthState>().logout();
    if (context.mounted) Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthState>();
    final locale = context.watch<LocaleState>();
    final stores = auth.stores;
    final noPermission = !auth.hasPermission(_kProcessInventoryPermission);

    return Scaffold(
      drawer: const AppNavDrawer(),
      appBar: AppBar(
        // Material 3's AppBar defaults to a pale surface color, not
        // colorScheme.primary — set explicitly for contrast with the
        // white-styled action buttons below.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(l10n.selectYourBranch),
      ),
      body: stores.isEmpty || noPermission
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, size: 48, color: Colors.black38),
                    const SizedBox(height: 12),
                    Text(
                      noPermission ? l10n.noInventoryPermissionMessage : l10n.noBranchAccessMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: () => _logout(context), child: Text(l10n.backToLogin)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = stores[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront),
                    title: Text(s.label(locale.locale.languageCode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _select(context, s),
                  ),
                );
              },
            ),
    );
  }
}
