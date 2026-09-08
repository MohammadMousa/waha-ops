import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_lite.dart';
import '../models/visit_operation.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';

// Collects one product + quantity and hands back the items list for a
// single-item operation. The destination branch and operation type are set
// in the visit header, not here (roadmap section 24) — this dialog only
// picks what's being moved.
Future<List<OperationItem>?> showAddOperationDialog(
  BuildContext context, {
  required int storeId,
  required String targetLabel,
}) {
  return showDialog<List<OperationItem>>(
    context: context,
    builder: (_) => AddOperationDialog(storeId: storeId, targetLabel: targetLabel),
  );
}

class AddOperationDialog extends StatefulWidget {
  final int storeId;
  final String targetLabel;
  const AddOperationDialog({super.key, required this.storeId, required this.targetLabel});

  @override
  State<AddOperationDialog> createState() => _AddOperationDialogState();
}

class _AddOperationDialogState extends State<AddOperationDialog> {
  final _search = TextEditingController();
  final _qty = TextEditingController(text: '1');
  Timer? _debounce;
  List<ProductLite> _results = [];
  ProductLite? _selected;
  bool _searching = false;
  String? _error;

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q.trim()));
  }

  Future<void> _runSearch(String q) async {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    setState(() => _searching = true);
    try {
      final results = await api.searchProducts(
        token: auth.token!,
        storeId: widget.storeId,
        q: q,
      );
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _submit() {
    final product = _selected;
    if (product == null) {
      setState(() => _error = 'Select a product');
      return;
    }
    final qty = int.tryParse(_qty.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a valid quantity');
      return;
    }
    Navigator.of(context).pop([
      OperationItem(productId: product.id, productLabel: product.label(), quantity: qty),
    ]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('To: ${widget.targetLabel}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: 'Search product',
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  label: Text(_selected!.label()),
                  onDeleted: () => setState(() => _selected = null),
                ),
              ),
            if (_results.isNotEmpty && _selected == null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final p = _results[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.label()),
                      subtitle: Text(p.barcode),
                      onTap: () => setState(() {
                        _selected = p;
                        _results = [];
                        _search.text = p.label();
                      }),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _qty,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
