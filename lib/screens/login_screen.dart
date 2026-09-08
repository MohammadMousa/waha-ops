import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../router/routes.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';

// PROCESS_INVENTORY is the permission required to run the visit workflow —
// granted to OPERATOR and BRANCH_ADMIN roles (not CASHIER, which only gets
// VIEW_INVENTORY). See ~/git/to_Frontend_AI_On_Inventory_Task.
const _kProcessInventoryPermission = 'PROCESS_INVENTORY';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (_username.text.trim().isEmpty || _pin.text.trim().isEmpty) {
      setState(() => _error = 'Enter username and PIN');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthState>();
    final api = context.read<ApiClient>();
    final visit = context.read<VisitState>();
    try {
      await auth.login(api, _username.text.trim(), _pin.text.trim());
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
    } catch (e) {
      setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Waha Ops',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Inventory visits',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Username'),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pin,
                    decoration: const InputDecoration(labelText: 'PIN'),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
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
