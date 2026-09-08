import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';

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
    final l10n = AppLocalizations.of(context)!;
    if (_username.text.trim().isEmpty || _pin.text.trim().isEmpty) {
      setState(() => _error = l10n.enterUsernameAndPin);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthState>();
    final api = context.read<ApiClient>();
    try {
      await auth.login(api, _username.text.trim(), _pin.text.trim());
      if (!mounted) return;
      // StoreSelectScreen handles all three cases: 0 stores (no access),
      // 1 store (auto-selects), many (shows the picker) — see
      // to_Frontend_AI_On_Inventory_Task [4]: the backend never picks one.
      Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = l10n.couldNotReachServer);
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
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleState>();
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => locale.toggle(),
                      child: Text(locale.locale.languageCode == 'ar' ? 'EN' : 'AR'),
                    ),
                  ),
                  Text(l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l10n.inventoryVisitsSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    decoration: InputDecoration(labelText: l10n.usernameLabel),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pin,
                    decoration: InputDecoration(labelText: l10n.pinLabel),
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
                        : Text(l10n.loginButton),
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
