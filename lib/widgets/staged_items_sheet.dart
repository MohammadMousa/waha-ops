import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/visit_operation.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';

// The staged-items review screen reached from AddOperationScreen's bottom
// badge button (Visit|TransfersX1.jpeg reference, 2026-09-09) — Transfer
// and Return share this exact sheet, only the title/icon differ by `type`.
// Items never show inline on the product list anymore; this is their only
// screen. Returns (via pop):
//   true — saved. The caller takes it from here — no "what's next" choice
//          here anymore (human lead, 2026-09-09): VisitHomeScreen already
//          has Transfer/Return and End Visit, asking again was redundant.
//   null — dismissed without saving (nothing changed beyond any removals
//          already applied through `onRemove`, which the caller owns)
Future<bool?> showStagedItemsSheet(
  BuildContext context, {
  required OperationType type,
  required List<OperationItem> items,
  required void Function(int index) onRemove,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _StagedItemsSheet(type: type, items: items, onRemove: onRemove),
  );
}

class _StagedItemsSheet extends StatefulWidget {
  final OperationType type;
  final List<OperationItem> items;
  final void Function(int index) onRemove;
  const _StagedItemsSheet({required this.type, required this.items, required this.onRemove});

  @override
  State<_StagedItemsSheet> createState() => _StagedItemsSheetState();
}

class _StagedItemsSheetState extends State<_StagedItemsSheet> {
  bool _saving = false;

  int? _finalStock(OperationItem item) {
    if (item.branchStock == null) return null;
    return widget.type == OperationType.transfer
        ? item.branchStock! + item.quantity
        : item.branchStock! - item.quantity;
  }

  void _remove(int index) {
    setState(() => widget.onRemove(index));
  }

  Future<void> _save() async {
    if (widget.items.isEmpty || _saving) return;
    setState(() => _saving = true);
    final visit = context.read<VisitState>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final ok = await visit.addOperation(api, auth.token!, widget.type, List.of(widget.items));
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      if (visit.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
      }
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.type == OperationType.transfer ? l10n.transferItemsTitle : l10n.returnItemsTitle;
    final icon = widget.type == OperationType.transfer ? Icons.swap_horiz : Icons.undo;
    final opColor =
        widget.type == OperationType.transfer ? Colors.green.shade600 : Colors.red.shade400;

    // Let the sheet expand all the way up until just the app bar (and the
    // branch name in it) stays visible, instead of stopping short with a
    // gap that made dragging feel like it started scrolling too early
    // (human lead, 2026-09-09).
    final mq = MediaQuery.of(context);
    final maxSize =
        (1 - (mq.padding.top + kToolbarHeight) / mq.size.height).clamp(0.5, 0.98);

    return DraggableScrollableSheet(
      initialChildSize: (maxSize - 0.2).clamp(0.4, maxSize),
      minChildSize: 0.4,
      maxChildSize: maxSize,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Standard drag-handle affordance — replaces the ambiguous
            // up-chevron from the reference mockup with the conventional
            // Material pattern for a draggable sheet.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Row(
                children: [
                  Icon(icon, color: opColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.itemColumnLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(l10n.qtyColumnLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(l10n.finalColumnLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = widget.items[i];
                  final finalStock = _finalStock(item);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AppConfig.resourceUrl(item.imageResourceId) == null
                              ? const Icon(Icons.inventory_2_outlined, color: Colors.black26, size: 20)
                              : Image.network(
                                  AppConfig.resourceUrl(item.imageResourceId)!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined,
                                      color: Colors.black26, size: 20),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.productLabel,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text('${item.quantity}', textAlign: TextAlign.center),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(finalStock?.toString() ?? '—', textAlign: TextAlign.center),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _remove(i),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E6E7E)),
                onPressed: (widget.items.isEmpty || _saving) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(l10n.saveChangesButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
