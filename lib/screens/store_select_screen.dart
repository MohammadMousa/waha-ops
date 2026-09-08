import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/branch.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';
import '../state/visit_state.dart';

// PROCESS_INVENTORY is the permission required to run the visit workflow —
// granted to OPERATOR and BRANCH_ADMIN roles (not CASHIER, which only gets
// VIEW_INVENTORY). See to_Frontend_AI_On_Inventory_Task.
const _kProcessInventoryPermission = 'PROCESS_INVENTORY';

// Shown after login with the employee's own accessible stores
// (from POST /api/pos/auth/login's `stores` list — never auto-picked by
// the backend, see to_Frontend_AI_On_Inventory_Task [4]/[5]/[6]). An empty
// list is a valid, real state: the employee has no branch access.
class StoreSelectScreen extends StatefulWidget {
  const StoreSelectScreen({super.key});

  @override
  State<StoreSelectScreen> createState() => _StoreSelectScreenState();
}

class _StoreSelectScreenState extends State<StoreSelectScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final stores = context.read<AuthState>().stores;
    if (stores.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(stores.first);
      });
    }
  }

  Future<void> _select(Branch store) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context)!;
    final lang = context.read<LocaleState>().locale.languageCode;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final visit = context.read<VisitState>();
    try {
      await auth.selectStore(api, store.id);
      if (!auth.hasPermission(_kProcessInventoryPermission)) {
        auth.clearStoreSelection();
        if (!mounted) return;
        setState(() => _error = l10n.noInventoryAccessAt(store.label(lang)));
        return;
      }
      final loaded = await visit.loadDestinationBranches(api, auth.token!, auth.storeId!);
      if (!mounted) return;
      if (!loaded) {
        setState(() => _error = visit.error ?? l10n.couldNotReachServer);
        return;
      }
      Navigator.of(context).pushReplacementNamed(Routes.visitHome);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.couldNotReachServer);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthState>().logout();
    if (mounted) Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthState>();
    final locale = context.watch<LocaleState>();
    final stores = auth.stores;

    return Scaffold(
      appBar: AppBar(
        // Material 3's AppBar defaults to a pale surface color, not
        // colorScheme.primary — set explicitly for contrast with the
        // white-styled action buttons below.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(l10n.selectYourBranch),
        actions: [
          TextButton(
            onPressed: () => locale.toggle(),
            child: Text(
              locale.locale.languageCode == 'ar' ? 'EN' : 'AR',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: l10n.logOut),
        ],
      ),
      body: stores.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, size: 48, color: Colors.black38),
                    const SizedBox(height: 12),
                    Text(l10n.noBranchAccessMessage,
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _logout, child: Text(l10n.backToLogin)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // The employee is already looking at the store list below,
                // so there's no "back to stores" to navigate to — just the
                // message and the one real alternative action (switch
                // accounts). Dismissing the banner is implicit in tapping
                // another store.
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(onPressed: _logout, child: Text(l10n.logOut)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _error = null),
                          tooltip: l10n.dismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: stores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = stores[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.storefront),
                          title: Text(s.label(locale.locale.languageCode)),
                          trailing: _busy
                              ? const SizedBox(
                                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.chevron_right),
                          onTap: _busy ? null : () => _select(s),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
