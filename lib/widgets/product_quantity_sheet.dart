import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/product_lite.dart';

// Shown after a product is identified (list tap, camera scan, or hardware
// wedge-scan) — styled after the reference "Product Inventory" popup.
// Only shows fields the backend actually returns — Branch Stock from
// GET /api/inventory/stock/{storeId} when available. No Route Stock /
// Max Capacity / Spoiled Items: none of those have a backend field yet
// (see docs/inventory.md — routing is Phase 2+).
Future<int?> showProductQuantitySheet(
  BuildContext context, {
  required ProductLite product,
  required int? branchStock, // null while unknown/unavailable
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ProductQuantitySheet(product: product, branchStock: branchStock),
  );
}

class ProductQuantitySheet extends StatefulWidget {
  final ProductLite product;
  final int? branchStock;
  const ProductQuantitySheet({super.key, required this.product, required this.branchStock});

  @override
  State<ProductQuantitySheet> createState() => _ProductQuantitySheetState();
}

class _ProductQuantitySheetState extends State<ProductQuantitySheet> {
  final _qty = TextEditingController(text: '1');
  String? _error;

  void _adjust(int delta) {
    final current = int.tryParse(_qty.text.trim()) ?? 0;
    final next = current + delta;
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(widget.product.label(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(widget.product.barcode, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('${l10n.branchStockLabel}: ${widget.branchStock?.toString() ?? '—'}'),
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
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  keyboardType: TextInputType.number,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }
}
