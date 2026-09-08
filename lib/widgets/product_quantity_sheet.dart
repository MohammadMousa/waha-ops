import 'package:flutter/material.dart';

import '../models/product_lite.dart';

// Shown after a product is identified (list tap, camera scan, or hardware
// wedge-scan). Only shows fields the backend actually returns —
// Branch Stock from GET /api/inventory/stock/{storeId} when available.
// No Route Stock / Max Capacity / Spoiled Items: none of those have a
// backend field yet (see docs/inventory.md — routing is Phase 2+).
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

  void _confirm() {
    final qty = int.tryParse(_qty.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid quantity');
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
          Text(widget.product.label(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                Text('Branch Stock: ${widget.branchStock?.toString() ?? '—'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qty,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _confirm(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: _confirm, child: const Text('Add')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
