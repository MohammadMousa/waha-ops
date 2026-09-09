import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';

// Shared Cancel/End Visit confirm-dialog + action flows. Both VisitHomeScreen
// and AddOperationScreen expose these in their footer now (human lead,
// 2026-09-09 nav redesign — Visit|ProductsX.jpeg reference), so the dialogs
// live here once instead of duplicated per screen. Callers own navigation
// afterward, since where each screen sends the employee differs slightly.

// Returns true if the visit was actually cancelled (local reset only —
// never calls completeVisit, see VisitState.reset()'s doc).
Future<bool> confirmAndCancelVisit(BuildContext context, VisitState visit) async {
  final l10n = AppLocalizations.of(context)!;
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
  if (discard != true) return false;
  visit.reset();
  return true;
}

// Completes the visit, shows the "saved" confirmation, and resets local
// state. Returns true only once all of that succeeded.
Future<bool> confirmAndEndVisit(
  BuildContext context,
  VisitState visit,
  ApiClient api,
  AuthState auth,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await visit.completeVisit(api, auth.token!);
  if (!context.mounted) return false;
  if (!ok) {
    if (visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
    return false;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.visitSavedTitle),
      content: Text(l10n.visitSavedMessage),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
    ),
  );
  if (!context.mounted) return true;
  visit.reset();
  return true;
}
