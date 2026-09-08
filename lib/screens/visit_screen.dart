import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/branch.dart';
import '../models/visit_operation.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';
import '../widgets/add_operation_dialog.dart';

// Roadmap section 33 — the source-of-truth layout:
//   Header: [ Branch ▼ (destination) ]  [ Transfer ▼ ]
//   Body:   list of operations added this visit
//   Footer: "End the visit and save activity"
class VisitScreen extends StatelessWidget {
  const VisitScreen({super.key});

  Future<void> _addOperation(BuildContext context) async {
    final visit = context.read<VisitState>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    if (visit.targetBranch == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a branch first')));
      return;
    }
    final items = await showAddOperationDialog(
      context,
      storeId: visit.originStoreId!,
      targetLabel: visit.targetBranch!.label,
    );
    if (items == null) return;
    final ok = await visit.addOperation(api, auth.token!, visit.operationType, items);
    if (!context.mounted) return;
    if (!ok && visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
  }

  Future<void> _removeOperation(BuildContext context, int index) async {
    final visit = context.read<VisitState>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final ok = await visit.removeOperation(api, auth.token!, index);
    if (!context.mounted) return;
    if (!ok && visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
  }

  Future<void> _endVisit(BuildContext context) async {
    final visit = context.read<VisitState>();
    if (visit.operations.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('End visit?'),
          content: const Text(
              'No operations were added during this visit. The backend requires at least one before completing.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ],
        ),
      );
      if (proceed != true) return;
      if (!context.mounted) return;
    }
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final ok = await visit.completeVisit(api, auth.token!);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Visit saved.')));
      visit.reset();
      Navigator.of(context).pushReplacementNamed(Routes.startVisit);
    } else if (visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = context.watch<VisitState>();
    if (visit.originStoreId == null) {
      return const Scaffold(body: Center(child: Text('No active visit.')));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Visit • ${visit.originStoreName}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Row(
              children: [
                _BranchSelector(
                  branches: visit.destinationBranches,
                  value: visit.targetBranch,
                  onChanged: (b) => visit.setTargetBranch(b),
                ),
                const SizedBox(width: 12),
                _OperationSelector(
                  value: visit.operationType,
                  onChanged: (t) => visit.setOperationType(t),
                ),
              ],
            ),
          ],
        ),
      ),
      body: visit.operations.isEmpty
          ? const Center(
              child: Text('No operations added yet.\nTap "Add Product" to start.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visit.operations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _OperationTile(
                op: visit.operations[i],
                onDelete: () => _removeOperation(context, i),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: visit.busy ? null : () => _addOperation(context),
                  icon: const Icon(Icons.add),
                  label: Text('Add ${visit.operationType.label}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: visit.busy ? null : () => _endVisit(context),
                  child: visit.busy
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('End Visit & Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  final List<Branch> branches;
  final Branch? value;
  final ValueChanged<Branch> onChanged;
  const _BranchSelector({required this.branches, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Branch>(
          value: value,
          hint: const Text('Select Branch', style: TextStyle(color: Colors.white70, fontSize: 13)),
          dropdownColor: Theme.of(context).colorScheme.primary,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          iconEnabledColor: Colors.white,
          items: branches
              .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
              .toList(),
          onChanged: (b) => b != null ? onChanged(b) : null,
        ),
      ),
    );
  }
}

class _OperationSelector extends StatelessWidget {
  final OperationType value;
  final ValueChanged<OperationType> onChanged;
  const _OperationSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OperationType>(
          value: value,
          dropdownColor: Theme.of(context).colorScheme.primary,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          iconEnabledColor: Colors.white,
          items: OperationType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) => t != null ? onChanged(t) : null,
        ),
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final VisitOperation op;
  final VoidCallback onDelete;
  const _OperationTile({required this.op, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(op.type == OperationType.transfer ? Icons.swap_horiz : Icons.undo),
        title: Text(op.items.map((i) => '${i.productLabel} × ${i.quantity}').join(', ')),
        subtitle: Text('${op.type.label} → ${op.targetStoreLabel}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Remove',
        ),
      ),
    );
  }
}
