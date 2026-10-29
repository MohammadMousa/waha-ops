import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/account_session.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';

// The employee's own signed-in devices (GET /api/auth/me/sessions) with
// sign-out for one or all of the others. Only reachable when the backend
// reports api_level 3 (see AppConfigState.supportsAccountSessions).
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<AccountSession>? _sessions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await context.read<ApiClient>().mySessions(context.read<AuthState>().token!);
      if (mounted) setState(() => _sessions = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<bool> _confirm(String body) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.signOutDevice)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _signOutOthers() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirm(l10n.signOutOthersConfirmBody)) return;
    if (!mounted) return;
    try {
      await context.read<ApiClient>().signOutOthers(context.read<AuthState>().token!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.signedOutOthersMessage)));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _signOutOne(AccountSession s) async {
    if (!await _confirm(_title(s, AppLocalizations.of(context)!))) return;
    if (!mounted) return;
    try {
      await context.read<ApiClient>().signOutSession(context.read<AuthState>().token!, s.ref);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _title(AccountSession s, AppLocalizations l10n) =>
      s.model ?? s.os ?? l10n.unknownDevice;

  String _subtitle(AccountSession s, AppLocalizations l10n) {
    final os = [s.os, s.osVersion].whereType<String>().join(' ');
    final seen = s.lastSeenAt ?? s.createdAt;
    final when = seen == null ? null : DateFormat.yMMMd().add_Hm().format(seen);
    return [
      if (os.isNotEmpty) os,
      if (s.appVersion != null) 'v${s.appVersion}',
      if (when != null) '${l10n.lastActive}: $when',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = _sessions;
    final hasOthers = sessions?.any((s) => !s.current) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activeSessionsTitle)),
      body: _error != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!),
                TextButton(onPressed: _load, child: Text(l10n.retry)),
              ]),
            )
          : sessions == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      for (final s in sessions)
                        ListTile(
                          leading: Icon(s.current ? Icons.phone_android : Icons.devices_other),
                          title: Text(_title(s, l10n)),
                          subtitle: Text(_subtitle(s, l10n)),
                          trailing: s.current
                              ? Chip(label: Text(l10n.thisDevice))
                              : IconButton(
                                  icon: const Icon(Icons.logout),
                                  tooltip: l10n.signOutDevice,
                                  onPressed: () => _signOutOne(s),
                                ),
                        ),
                      if (!hasOthers)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(child: Text(l10n.noOtherSessions)),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: hasOthers
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOutOtherDevices),
                  onPressed: _signOutOthers,
                ),
              ),
            )
          : null,
    );
  }
}
