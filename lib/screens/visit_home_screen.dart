import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/visit_operation.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../state/app_config_state.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';
import '../state/visit_state.dart';
import '../widgets/app_nav_drawer.dart';
import '../widgets/visit_actions.dart';
import 'add_operation_screen.dart';

// The employee's home screen for a branch visit (roadmap §33 / Visit1.png
// reference): branch pinned in the header, a menu for changing branch, a
// language toggle, two big Transfer/Return buttons, and Cancel/End Visit
// in the footer. Reaching this screen does NOT start a visit — the branch
// is already picked manually on StoreSelectScreen. Both starting flows are
// allowed (human lead, 2026-09-08): the footer's own "Start Visit" button
// starts it explicitly with no operation picked yet, OR tapping Transfer/
// Return starts it implicitly as a side effect if it isn't active yet.
// Empty visits (started, nothing added) are allowed to save — that tells
// the office the employee visited and found nothing to do.
class VisitHomeScreen extends StatefulWidget {
  const VisitHomeScreen({super.key});

  @override
  State<VisitHomeScreen> createState() => _VisitHomeScreenState();
}

class _VisitHomeScreenState extends State<VisitHomeScreen> {
  // Returns false only on a failed start (error already surfaced via
  // SnackBar) — true if the visit is active, whether it already was or was
  // just started now.
  Future<bool> _ensureVisitStarted() async {
    final visit = context.read<VisitState>();
    if (visit.status == VisitStatus.active) return true;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final started = await visit.startVisit(api, auth.token!, auth.storeId!);
    if (!mounted) return false;
    if (!started && visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
    return started;
  }

  Future<void> _openOperation(OperationType type) async {
    final visit = context.read<VisitState>();

    if (!await _ensureVisitStarted() || !mounted) return;

    // No destination picker — every operation is company↔branch (see
    // VisitOperation's doc comment), so there's nothing else to choose here.
    // AddOperationScreen pops `true` once the operation is actually saved —
    // just land back here and confirm it; Transfer/Return/End Visit are
    // already right here, no need to ask what's next (human lead, 2026-09-09).
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AddOperationScreen(
        type: type,
        storeId: visit.originStoreId!,
      ),
    ));
    if (saved == true && mounted) await _showOperationSaved();
  }

  Future<void> _showOperationSaved() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.operationSavedTitle),
        content: Text(l10n.operationSavedMessage),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok)),
        ],
      ),
    );
  }

  Future<void> _changeBranch() async {
    final l10n = AppLocalizations.of(context)!;
    final visit = context.read<VisitState>();
    if (visit.status == VisitStatus.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.endVisitFirstTitle),
          content: Text(l10n.endVisitFirstBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true), child: Text(l10n.endVisitAndSwitch)),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
      final api = context.read<ApiClient>();
      final auth = context.read<AuthState>();
      final ok = await visit.completeVisit(api, auth.token!);
      if (!mounted) return;
      if (!ok) {
        if (visit.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
        }
        return;
      }
    }
    visit.reset();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
  }

  Future<void> _cancelVisit() async {
    final visit = context.read<VisitState>();
    final cancelled = await confirmAndCancelVisit(context, visit);
    if (!cancelled || !mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
  }

  Future<void> _endVisit() async {
    final visit = context.read<VisitState>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final ended = await confirmAndEndVisit(context, visit, api, auth);
    if (!ended || !mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visit = context.watch<VisitState>();
    final auth = context.watch<AuthState>();
    final locale = context.watch<LocaleState>();
    final appConfig = context.watch<AppConfigState>();
    final visitActive = visit.status == VisitStatus.active;
    // auth.storeId is known the instant the branch is picked on
    // StoreSelectScreen — visit.originStoreId only exists once the visit
    // has actually started on the backend, which is later (manual Start
    // Visit, or the first Transfer/Return tap). Prefer the visit's own
    // once it exists (belt-and-braces, same store either way), but don't
    // wait on it just to show the branch that's already been chosen —
    // showing the app name here instead read as "which branch am I even
    // on?" (human lead, 2026-09-09).
    final currentStoreId = visit.originStoreId ?? auth.storeId;
    // The login session's `stores` list now carries the real displayName
    // (backend fix confirmed — see to_Frontend_AI_On_Inventory_Task [7]).
    final originLabel = auth.stores
        .where((b) => b.id == currentStoreId)
        .map((b) => b.label(locale.locale.languageCode))
        .firstOrNull;

    return Scaffold(
      drawer: AppNavDrawer(
        extraItems: [
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(l10n.changeBranch),
            onTap: () {
              Navigator.of(context).pop();
              _changeBranch();
            },
          ),
        ],
      ),
      appBar: AppBar(
        // Material 3's AppBar defaults to a pale surface color, not
        // colorScheme.primary — set explicitly, since the actions below
        // assume a dark background behind their white/icon foreground.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(originLabel ??
            visit.originStoreName ??
            appConfig.title(locale.locale.languageCode) ??
            l10n.appTitle),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: _BigOperationButton(
                      icon: Icons.swap_horiz,
                      label: l10n.transferLabel,
                      // Light green/red backgrounds are purely a secondary,
                      // color-only distinction between the two operation
                      // types (human lead, 2026-09-09) — the icon still
                      // carries the real meaning.
                      background: const Color(0xFFE8F5E9),
                      onTap: visit.busy ? null : () => _openOperation(OperationType.transfer),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: _BigOperationButton(
                      icon: Icons.undo,
                      label: l10n.returnLabel,
                      background: const Color(0xFFFFEBEE),
                      onTap: visit.busy ? null : () => _openOperation(OperationType.ret),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (visit.busy)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: visitActive
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: visit.busy ? null : _cancelVisit,
                        child: Text(l10n.cancelVisit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: visit.busy ? null : _endVisit,
                        child: visit.busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l10n.endVisit),
                      ),
                    ),
                  ],
                )
              // Manual start, per the two allowed flows: this button starts
              // the visit with no operation picked yet; Transfer/Return
              // above starts it implicitly instead if tapped first.
              : FilledButton(
                  onPressed: visit.busy ? null : () => _ensureVisitStarted(),
                  child: visit.busy
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.startVisitButton),
                ),
        ),
      ),
    );
  }
}

class _BigOperationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback? onTap;
  const _BigOperationButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
