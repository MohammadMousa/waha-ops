import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/visit_operation.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';
import '../state/visit_state.dart';
import '../widgets/branch_picker_sheet.dart';
import 'add_operation_screen.dart';

// The employee's home screen for a branch visit (roadmap §33 / Visit1.png
// reference): branch pinned in the header, a menu for changing branch, a
// language toggle, two big Transfer/Return buttons, and Cancel/End Visit
// in the footer. The visit auto-starts the moment this screen is reached
// — there's no separate "Start Visit" step (see human lead's notes,
// 2026-09-08): reaching this screen after picking a branch IS starting
// the visit. Empty visits (started, nothing added) are allowed to save —
// that tells the office the employee visited and found nothing to do.
class VisitHomeScreen extends StatefulWidget {
  const VisitHomeScreen({super.key});

  @override
  State<VisitHomeScreen> createState() => _VisitHomeScreenState();
}

class _VisitHomeScreenState extends State<VisitHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisitStarted());
  }

  Future<void> _ensureVisitStarted() async {
    final visit = context.read<VisitState>();
    if (visit.status == VisitStatus.active) return;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    await visit.startVisit(api, auth.token!);
    if (!mounted) return;
    if (visit.status != VisitStatus.active && visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
  }

  Future<void> _openOperation(OperationType type) async {
    final visit = context.read<VisitState>();
    final lang = context.read<LocaleState>().locale.languageCode;
    var target = visit.targetBranch;
    if (visit.destinationBranches.length > 1) {
      final picked = await showBranchPickerSheet(context, visit.destinationBranches, lang);
      if (picked == null) return;
      visit.setTargetBranch(picked);
      target = picked;
    }
    if (target == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddOperationScreen(
        type: type,
        storeId: visit.originStoreId!,
        targetLabel: target!.label(lang),
      ),
    ));
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
    final l10n = AppLocalizations.of(context)!;
    final visit = context.read<VisitState>();
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.cancelVisitConfirmTitle),
        content: Text(l10n.cancelVisitConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepVisit)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discardVisit),
          ),
        ],
      ),
    );
    if (discard != true) return;
    // Undo only — never call completeVisit here. See VisitState's reset() doc.
    visit.reset();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
  }

  Future<void> _endVisit() async {
    final l10n = AppLocalizations.of(context)!;
    final visit = context.read<VisitState>();
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
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.visitSavedTitle),
        content: Text(l10n.visitSavedMessage),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok)),
        ],
      ),
    );
    visit.reset();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.storeSelect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visit = context.watch<VisitState>();
    final auth = context.watch<AuthState>();
    final locale = context.watch<LocaleState>();
    final starting = visit.status != VisitStatus.active;
    // Prefer the branch's real display name (from the employee's own
    // accessible-stores list, fetched at login) over the visit-start
    // response's raw `storeName` slug — same displayName gap as the
    // destination-branch list, see to_Backend_AI_On_Inventory_Task.
    final originLabel = auth.stores
        .where((b) => b.id == visit.originStoreId)
        .map((b) => b.label(locale.locale.languageCode))
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Material 3's AppBar defaults to a pale surface color, not
        // colorScheme.primary — set explicitly, since the actions below
        // assume a dark background behind their white/icon foreground.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(originLabel ?? visit.originStoreName ?? l10n.appTitle),
        actions: [
          TextButton(
            onPressed: () => locale.toggle(),
            child: Text(
              locale.locale.languageCode == 'ar' ? 'EN' : 'AR',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (v) {
              if (v == 'change_branch') _changeBranch();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'change_branch', child: Text(l10n.changeBranch)),
            ],
          ),
        ],
      ),
      body: starting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.startingVisit),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: _BigOperationButton(
                      icon: Icons.swap_horiz,
                      label: l10n.transferLabel,
                      onTap: () => _openOperation(OperationType.transfer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _BigOperationButton(
                      icon: Icons.undo,
                      label: l10n.returnLabel,
                      onTap: () => _openOperation(OperationType.ret),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: starting || visit.busy ? null : _cancelVisit,
                  child: Text(l10n.cancelVisit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: starting || visit.busy ? null : _endVisit,
                  child: visit.busy
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.endVisit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigOperationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BigOperationButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
