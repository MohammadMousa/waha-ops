import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/product_lite.dart';
import '../models/visit_operation.dart';
import '../state/locale_state.dart';

// Shown after a product is identified (list tap, camera scan, or hardware
// wedge-scan) — restyled after the handheld "Product Inventory" reference
// (ksnip_20260908-201753.png): title/close header, product image
// placeholder, name, a single Branch Stock stat (the only stock field the
// backend actually returns — no Route Stock / Max Capacity, those have no
// backend field yet, see docs/inventory.md), one quantity spinner (type or
// tap +/-, replacing the reference's separate inputs), and a live Ending
// Inventory readout. Transfer and Return share this exact popup — only the
// title and the sign on Ending Inventory change with `type` (transfer is
// company → branch, so it replenishes the origin branch; return is branch
// → company, so it drains it — confirmed with the human lead, 2026-09-08,
// opposite of what was first assumed here).
Future<int?> showProductQuantitySheet(
  BuildContext context, {
  required ProductLite product,
  required int? branchStock, // null while unknown/unavailable
  required OperationType type,
  // Non-null when this product is already staged — re-opens on its
  // existing quantity so confirming edits that entry instead of the
  // caller adding a duplicate row for the same product (human lead,
  // 2026-09-09: scanning/picking the same item twice must edit, not
  // duplicate).
  int? initialQuantity,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ProductQuantitySheet(
      product: product,
      branchStock: branchStock,
      type: type,
      initialQuantity: initialQuantity ?? 1,
    ),
  );
}

class ProductQuantitySheet extends StatefulWidget {
  final ProductLite product;
  final int? branchStock;
  final OperationType type;
  final int initialQuantity;
  const ProductQuantitySheet({
    super.key,
    required this.product,
    required this.branchStock,
    required this.type,
    this.initialQuantity = 1,
  });

  @override
  State<ProductQuantitySheet> createState() => _ProductQuantitySheetState();
}

class _ProductQuantitySheetState extends State<ProductQuantitySheet> {
  late final _qty = TextEditingController(text: '${widget.initialQuantity}');
  String? _error;

  String? get _imageUrl => AppConfig.resourceUrl(widget.product.imageResourceId);

  int get _enteredQty => int.tryParse(_qty.text.trim()) ?? 0;

  // Transfer replenishes the origin branch (company → branch); return
  // drains it (branch → company).
  int? get _endingInventory {
    if (widget.branchStock == null) return null;
    return widget.type == OperationType.transfer
        ? widget.branchStock! + _enteredQty
        : widget.branchStock! - _enteredQty;
  }

  void _adjust(int delta) {
    final next = _enteredQty + delta;
    if (next < 1) return;
    setState(() {
      _qty.text = '$next';
      _error = null;
    });
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    final qty = int.tryParse(_qty.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = l10n.enterValidQuantity);
      return;
    }
    Navigator.of(context).pop(qty);
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = context.watch<LocaleState>().locale.languageCode;
    final primary = Theme.of(context).colorScheme.primary;
    final title =
        widget.type == OperationType.transfer ? l10n.productTransferTitle : l10n.productReturnTitle;
    final ending = _endingInventory;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          // The keyboard eats a big chunk of a phone's screen height — this
          // content doesn't fit anymore once it's up, so it must scroll
          // instead of overflowing (Flutter's debug-mode yellow/black
          // stripes were showing through it, human lead, 2026-09-09).
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageUrl == null
                    ? const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26)
                    : Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.black26),
                      ),
              ),
              const SizedBox(height: 16),
              Text(widget.product.label(lang),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(widget.product.barcode, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.branchStockLabel,
                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        children: [
                          TextSpan(text: widget.branchStock?.toString() ?? '—'),
                          TextSpan(
                            text: '  ${l10n.unitsSuffix}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.normal, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.quantityLabel, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StepperButton(icon: Icons.remove, onTap: () => _adjust(-1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qty,
                      // No autofocus — the stepper +/- buttons are the
                      // primary way this gets used, popping the keyboard
                      // open on every scan/tap was just in the way (human
                      // lead, 2026-09-09).
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _confirm(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StepperButton(icon: Icons.add, onTap: () => _adjust(1)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.endingInventoryLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(
                    ending != null ? '$ending ${l10n.unitsSuffix}' : '—',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(onPressed: _confirm, child: Text(l10n.addButton)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }
}
