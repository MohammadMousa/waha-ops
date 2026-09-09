import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../router/routes.dart';
import '../state/app_config_state.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';

// Consolidates the language toggle and logout into one menu, reachable from
// any screen's hamburger icon — per the human lead: those two no longer
// live in individual screen headers (2026-09-09, Visit|NavX.jpeg
// reference). Identity line is the real employeeName/roleLabel from login
// (see to_Frontend_AI_On_Inventory_Task [10]), falling back to the
// username for an older cached session that hasn't re-logged-in since.
class AppNavDrawer extends StatelessWidget {
  // Extra items shown between Language and Logout — e.g. "Change Branch"
  // on VisitHomeScreen. Optional so most screens can just omit it.
  final List<Widget> extraItems;

  const AppNavDrawer({super.key, this.extraItems = const []});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthState>();
    final locale = context.watch<LocaleState>();
    final appConfig = context.watch<AppConfigState>();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.person, size: 36, color: Colors.black45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.employeeName ??
                        auth.username ??
                        appConfig.title(locale.locale.languageCode) ??
                        l10n.appTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (auth.roleLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(auth.roleLabel!, style: const TextStyle(color: Colors.black54)),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.languageMenuLabel),
              onTap: () {
                locale.toggle();
                Navigator.of(context).pop();
              },
            ),
            ...extraItems,
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.power_settings_new),
                label: Text(l10n.logOut),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await context.read<AuthState>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
