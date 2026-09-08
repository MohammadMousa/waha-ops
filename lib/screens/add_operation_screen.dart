import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_lite.dart';
import '../models/visit_operation.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';
import '../widgets/product_quantity_sheet.dart';
import 'camera_scan_screen.dart';

// Full-screen product list (search + scan), matching the Products-screen
// convention: search field with a scan button beside it. Each identified
// product (list tap, camera scan, or hardware wedge-scan via the search
// field's submit) opens the quantity popup, then queues onto a staging
// list. "Save" submits every staged item as ONE operation call — the
// backend's items array already supports multiple products per operation
// (see docs/inventory.md), so one scan session -> one API call.
class AddOperationScreen extends StatefulWidget {
  final OperationType type;
  final int storeId; // origin store — product search/stock scope
  final String targetLabel;

  const AddOperationScreen({
    super.key,
    required this.type,
    required this.storeId,
    required this.targetLabel,
  });

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<ProductLite> _results = [];
  bool _searching = false;
  Map<int, int>? _stock; // productId -> quantity; null while unavailable
  final List<OperationItem> _staged = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    try {
      final stock = await api.getStock(token: auth.token!, storeId: widget.storeId);
      if (mounted) setState(() => _stock = stock);
    } catch (_) {
      // Backend endpoint may not be deployed yet — Branch Stock just shows
      // "—" in the popup instead of blocking the scan/search flow.
    }
  }

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
      final results = await api.searchProducts(token: auth.token!, storeId: widget.storeId, q: q);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // Handles both a hardware scanner (keyboard wedge: types the barcode into
  // the search field, then sends Enter) and a manual Enter on typed text —
  // tries an exact barcode match first, falls back to the text search
  // results already shown.
  Future<void> _onSearchSubmitted(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    try {
      final product = await api.getProductByBarcode(code, token: auth.token!, storeId: widget.storeId);
      if (!mounted) return;
      await _pickProduct(product);
    } on ProductNotFoundException {
      // Not a barcode — leave the already-running text search results as-is.
    } on ProductNotSellableException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      // Network/other — text search results remain the fallback.
    }
  }

  Future<void> _scanWithCamera() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraScanScreen()),
    );
    if (code == null || !mounted) return;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    try {
      final product = await api.getProductByBarcode(code, token: auth.token!, storeId: widget.storeId);
      if (!mounted) return;
      await _pickProduct(product);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickProduct(ProductLite product) async {
    final qty = await showProductQuantitySheet(
      context,
      product: product,
      branchStock: _stock?[product.id],
    );
    if (qty == null) return;
    setState(() {
      _staged.add(OperationItem(productId: product.id, productLabel: product.label(), quantity: qty));
      _results = [];
      _search.clear();
    });
  }

  void _removeStaged(int index) => setState(() => _staged.removeAt(index));

  Future<void> _save() async {
    if (_staged.isEmpty) return;
    setState(() => _saving = true);
    final visit = context.read<VisitState>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final ok = await visit.addOperation(api, auth.token!, widget.type, List.of(_staged));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
    } else if (visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.type.label} → ${widget.targetLabel}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search or scan a product',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    tooltip: 'Scan with camera',
                    onPressed: _scanWithCamera,
                  ),
                ),
              ],
            ),
          ),
          if (_staged.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_staged.length} item(s) added',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  ..._staged.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text('${e.value.productLabel} × ${e.value.quantity}')),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removeStaged(e.key),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _search.text.isEmpty ? 'Search or scan to find a product' : 'No matches',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final p = _results[i];
                      return ListTile(
                        title: Text(p.label()),
                        subtitle: Text(p.barcode),
                        trailing: _stock?[p.id] != null ? Text('${_stock![p.id]} in stock') : null,
                        onTap: () => _pickProduct(p),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: (_staged.isEmpty || _saving) ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save ${_staged.length} item(s)'),
          ),
        ),
      ),
    );
  }
}
