import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/app_config_state.dart';
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
  bool _showPin = false;
  String? _error;

  // Lockout: while > 0 the form is disabled and the banner ticks down.
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;
  bool get _locked => _lockSecondsLeft > 0;
  String _lockHeadline = 'Account temporarily locked.';

  void _startLock(int seconds) {
    _lockTimer?.cancel();
    setState(() => _lockSecondsLeft = seconds);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _lockSecondsLeft--;
        if (_lockSecondsLeft <= 0) {
          _lockSecondsLeft = 0;
          _error = null;
          t.cancel();
        }
      });
    });
  }

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
      // StoreSelectScreen handles every case from here: 0 stores (no
      // branch access), no PROCESS_INVENTORY permission (resolved at
      // login, applies to every store), or a normal picker — always a
      // manual tap, never auto-selected, even with only one store.
      Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
    } on AccountLockedException catch (e) {
      // Do not auto-retry on a failed login — each retry would count as
      // another attempt. The countdown just disables the form until the
      // backend's own wait time is up.
      final wait = e.retryAfterSeconds;
      if (!mounted) return;
      if (wait != null && wait > 0) {
        _lockHeadline = e.headline;
        _startLock(wait);
      } else {
        setState(() => _error = loginFailureText(e));
      }
    } on ApiException catch (e) {
      setState(() => _error = loginFailureText(e));
    } catch (e) {
      setState(() => _error = l10n.couldNotReachServer);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleState>();
    final appConfig = context.watch<AppConfigState>();
    final title = appConfig.title(locale.locale.languageCode) ?? l10n.appTitle;
    final disabled = _loading || _locked;
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
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(l10n.inventoryVisitsSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    enabled: !disabled,
                    decoration: InputDecoration(labelText: l10n.usernameLabel),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pin,
                    enabled: !disabled,
                    decoration: InputDecoration(
                      labelText: l10n.pinLabel,
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPin = !_showPin),
                      ),
                    ),
                    obscureText: !_showPin,
                    keyboardType: TextInputType.number,
                    // Backend moved employee PINs to 6 digits; existing
                    // accounts keep their old 4-digit PIN until reset (see
                    // to_Kiosk_AI_On_Auth_Task), so this only caps the max.
                    maxLength: 6,
                    onSubmitted: (_) => _login(),
                  ),
                  if (_locked || _error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _locked
                          ? '$_lockHeadline Try again in ${formatMmSs(_lockSecondsLeft)}'
                          : _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: disabled ? null : _login,
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
