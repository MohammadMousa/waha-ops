import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/branch.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';

// PROCESS_INVENTORY is the permission required to run the visit workflow —
// granted to OPERATOR and BRANCH_ADMIN roles (not CASHIER, which only gets
// VIEW_INVENTORY). See to_Frontend_AI_On_Inventory_Task.
const _kProcessInventoryPermission = 'PROCESS_INVENTORY';

// Shown after login with the employee's own accessible stores
// (from POST /api/pos/auth/login's `stores` list — never auto-picked by
// the backend, see to_Frontend_AI_On_Inventory_Task [4]/[5]). An empty
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
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final visit = context.read<VisitState>();
    try {
      await auth.selectStore(api, store.id);
      if (!auth.hasPermission(_kProcessInventoryPermission)) {
        await auth.logout();
        if (!mounted) return;
        setState(() => _error = 'This account is not authorized for inventory operations.');
        return;
      }
      final loaded = await visit.loadDestinationBranches(api, auth.token!, auth.storeId!);
      if (!mounted) return;
      if (!loaded) {
        setState(() => _error = visit.error ?? 'Could not load branches');
        return;
      }
      Navigator.of(context).pushReplacementNamed(Routes.startVisit);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server');
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
    final auth = context.watch<AuthState>();
    final stores = auth.stores;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Branch'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Log out')],
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
                    const Text('This account has no branch access.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _logout, child: const Text('Back to login')),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
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
                          title: Text(s.label),
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
