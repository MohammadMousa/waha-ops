import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/category.dart';
import '../models/product_lite.dart';
import '../models/visit_operation.dart';
import '../router/routes.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../state/app_config_state.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';
import '../state/visit_state.dart';
import '../widgets/app_nav_drawer.dart';
import '../widgets/filter_products_sheet.dart';
import '../widgets/product_quantity_sheet.dart';
import '../widgets/staged_items_sheet.dart';
import '../widgets/visit_actions.dart';
import 'camera_scan_screen.dart';

// Full-screen product list (browse + search + filter + scan), matching the
// Products-screen convention (Visit|ProductsX.jpeg reference, 2026-09-09).
// Shows a default browsable list of every product on load (GET
// /api/products) — search (GET /api/products/search) only replaces that
// list once the employee types something; it never starts empty. Each
// identified product (list tap, "+" button, camera scan, or hardware
// wedge-scan via the search field's submit) opens the quantity popup, then
// queues onto a staging list — but that list never shows inline here
// anymore; the bottom badge button is its only entry point
// (staged_items_sheet.dart), matching Visit|TransfersX1.jpeg.
class AddOperationScreen extends StatefulWidget {
  final OperationType type;
  final int storeId; // origin store — product search/stock scope, and the
  // app bar title (the branch alone, per the human lead: the operation
  // type is conveyed by the footer badge's icon now, not the title) —
  // looked up live from auth.stores in build(), NOT passed in as a fixed
  // string: a precomputed label went stale on a language toggle while
  // already on this screen (human lead, 2026-09-09).

  const AddOperationScreen({
    super.key,
    required this.type,
    required this.storeId,
  });

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  List<ProductLite> _browseList = [];
  List<ProductLite>? _searchResults; // null = no active query, show browse list
  bool _loadingBrowse = true;
  bool _searching = false;
  bool _inStockOnly = false;
  int? _categoryId;
  String _descriptionKeyword = '';
  Map<int, int>? _stock; // productId -> quantity; null while unavailable
  List<Category> _categories = [];
  final List<OperationItem> _staged = [];

  // Background hardware-scanner capture — a keyboard-wedge scanner (or a
  // rugged device's built-in scan trigger, which behaves the same way)
  // "types" the barcode fast then sends Enter, regardless of what's
  // focused. HardwareKeyboard.instance sees every key event app-wide, not
  // just ones aimed at a focused widget, so this works without the
  // employee ever tapping the search field first (human lead, 2026-09-09).
  // Skipped entirely while the search field itself has focus — its own
  // onSubmitted already handles that case, no need to double up.
  final _scanBuffer = StringBuffer();
  DateTime? _lastScanKeyTime;

  @override
  void initState() {
    super.initState();
    _loadStock();
    _loadBrowseList();
    _loadCategories();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (_searchFocusNode.hasFocus) return false; // let the field's own onSubmitted handle it
    if (event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _scanBuffer.toString();
      _scanBuffer.clear();
      if (code.isNotEmpty) _handleScannedCode(code, isDefiniteScan: true);
      return code.isNotEmpty;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return false;
    final now = DateTime.now();
    // A gap this long means human/unrelated typing, not a scanner burst —
    // start a fresh buffer instead of concatenating onto stale input.
    if (_lastScanKeyTime != null && now.difference(_lastScanKeyTime!) > const Duration(milliseconds: 150)) {
      _scanBuffer.clear();
    }
    _lastScanKeyTime = now;
    _scanBuffer.write(char);
    return false;
  }

  Future<void> _loadCategories() async {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    try {
      final categories = await api.getCategories(token: auth.token!, storeId: widget.storeId);
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // Filter sheet just shows "All Categories" only if this fails.
    }
  }

  Future<void> _loadStock() async {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    try {
      final stock = await api.getStock(token: auth.token!, storeId: widget.storeId);
      if (mounted) setState(() => _stock = stock);
    } catch (_) {
      // Backend endpoint may not be deployed yet — Branch Stock just shows
      // "—" in the popup instead of blocking the browse/search/scan flow.
    }
  }

  Future<void> _loadBrowseList() async {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    setState(() => _loadingBrowse = true);
    try {
      final products = await api.getProducts(token: auth.token!, storeId: widget.storeId);
      if (mounted) setState(() => _browseList = products);
    } catch (_) {
      if (mounted) setState(() => _browseList = []);
    } finally {
      if (mounted) setState(() => _loadingBrowse = false);
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _searchResults = null);
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
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // Every barcode-identification path (typed Enter in the search field,
  // camera scan, background hardware-scanner capture) funnels through here.
  // `isDefiniteScan` distinguishes them: a manual Enter after typed text is
  // ambiguous (could be a partial product name, not a barcode at all) so a
  // miss there silently falls back to the text search results already on
  // screen; camera/hardware scans are unambiguous, so a miss there always
  // pops an error instead of failing silently (human lead, 2026-09-09).
  Future<void> _handleScannedCode(String value, {required bool isDefiniteScan}) async {
    final code = value.trim();
    if (code.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    try {
      final product = await api.getProductByBarcode(code, token: auth.token!, storeId: widget.storeId);
      if (!mounted) return;
      await _pickProduct(product);
    } on ProductNotFoundException catch (e) {
      if (!mounted) return;
      if (isDefiniteScan) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      // Else: not a barcode — leave the already-running text search results as-is.
    } on ProductNotSellableException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ApiException catch (e) {
      if (mounted && isDefiniteScan) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted && isDefiniteScan) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotReachServer)));
      }
      // Else: network/other — text search results remain the fallback.
    }
  }

  Future<void> _scanWithCamera() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraScanScreen()),
    );
    if (code == null || !mounted) return;
    await _handleScannedCode(code, isDefiniteScan: true);
  }

  Future<void> _pickProduct(ProductLite product) async {
    final lang = context.read<LocaleState>().locale.languageCode;
    // null only means the stock fetch itself never succeeded (backend down,
    // endpoint missing) — a successful fetch with no entry for this product
    // means zero on hand, not "unknown", so it still gets a real number.
    final branchStock = _stock == null ? null : (_stock![product.id] ?? 0);
    // Already staged? Re-open on its existing quantity so this edits that
    // row instead of adding a duplicate one for the same product.
    final existingIndex = _staged.indexWhere((i) => i.productId == product.id);
    final qty = await showProductQuantitySheet(
      context,
      product: product,
      branchStock: branchStock,
      type: widget.type,
      initialQuantity: existingIndex == -1 ? null : _staged[existingIndex].quantity,
    );
    if (qty == null) return;
    setState(() {
      final item = OperationItem(
        productId: product.id,
        productLabel: product.label(lang),
        quantity: qty,
        branchStock: branchStock,
        imageResourceId: product.imageResourceId,
      );
      if (existingIndex == -1) {
        _staged.add(item);
      } else {
        _staged[existingIndex] = item;
      }
      _searchResults = null;
      _search.clear();
    });
  }

  Future<void> _openFilter() async {
    final lang = context.read<LocaleState>().locale.languageCode;
    final result = await showFilterProductsSheet(
      context,
      current: ProductFilter(
        name: _search.text,
        categoryId: _categoryId,
        descriptionKeyword: _descriptionKeyword,
        inStockOnly: _inStockOnly,
      ),
      categories: _categories,
      languageCode: lang,
    );
    if (result == null || !mounted) return;
    setState(() {
      _inStockOnly = result.inStockOnly;
      _categoryId = result.categoryId;
      _descriptionKeyword = result.descriptionKeyword;
    });
    if (result.barcode.isNotEmpty) {
      _search.text = result.barcode;
      // A dedicated Barcode field — unlike the general search box, a miss
      // here is unambiguous, so it gets the same error handling as a scan.
      await _handleScannedCode(result.barcode, isDefiniteScan: true);
    } else if (result.name.isNotEmpty) {
      _search.text = result.name;
      await _runSearch(result.name);
    } else {
      _search.clear();
      setState(() => _searchResults = null);
    }
  }

  Future<void> _openStagedItems() async {
    final saved = await showStagedItemsSheet(
      context,
      type: widget.type,
      items: _staged,
      onRemove: (i) => _staged.removeAt(i),
    );
    if (!mounted) return;
    if (saved != true) {
      // Dismissed without saving — removals (if any) still apply.
      setState(() {});
      return;
    }
    setState(() => _staged.clear());
    // Pop back to VisitHomeScreen — it already has Transfer/Return and End
    // Visit, no need to ask what's next here (human lead, 2026-09-09).
    Navigator.of(context).pop(true);
  }

  Future<void> _cancelVisit() async {
    final visit = context.read<VisitState>();
    final cancelled = await confirmAndCancelVisit(context, visit);
    if (!cancelled || !mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.storeSelect, (_) => false);
  }

  Future<void> _endVisit() async {
    if (_staged.isNotEmpty) {
      // Don't even attempt the API call — this operation's items aren't
      // saved yet, so completing now would either fail confusingly or (once
      // the backend allows empty-visit completion again) silently drop
      // them. Tell the employee to finish it first (human lead, 2026-09-09).
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.finishOperationFirstMessage)));
      return;
    }
    final visit = context.read<VisitState>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final ended = await confirmAndEndVisit(context, visit, api, auth);
    if (!ended || !mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.storeSelect, (_) => false);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _debounce?.cancel();
    _search.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = context.watch<LocaleState>().locale.languageCode;
    final visit = context.watch<VisitState>();
    final auth = context.watch<AuthState>();
    final appConfig = context.watch<AppConfigState>();
    final originLabel = auth.stores
            .where((b) => b.id == widget.storeId)
            .map((b) => b.label(lang))
            .firstOrNull ??
        appConfig.title(lang) ??
        l10n.appTitle;
    final base = _searchResults ?? _browseList;
    // Category and description-keyword filter client-side, over whatever
    // page is currently loaded — same limitation _inStockOnly already had
    // (browse/search only expose a text-query param server-side, not these).
    final displayed = base.where((p) {
      if (_inStockOnly && (_stock?[p.id] ?? 0) <= 0) return false;
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (_descriptionKeyword.isNotEmpty &&
          !p.descriptionText(lang).toLowerCase().contains(_descriptionKeyword.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    final opIcon = widget.type == OperationType.transfer ? Icons.swap_horiz : Icons.undo;
    // Same light green/red distinction as the front-page Transfer/Return
    // buttons, carried onto this screen's own operation-type badge.
    final opColor =
        widget.type == OperationType.transfer ? Colors.green.shade600 : Colors.red.shade400;

    return Scaffold(
      drawer: const AppNavDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Text(originLabel),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: l10n.searchOrScanProduct,
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
                    onSubmitted: (v) => _handleScannedCode(v, isDefiniteScan: false),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.filter_alt_outlined),
                  tooltip: l10n.filterProductsTitle,
                  onPressed: _openFilter,
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
                    tooltip: l10n.scanBarcode,
                    onPressed: _scanWithCamera,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingBrowse && displayed.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : displayed.isEmpty
                    ? Center(
                        child: Text(l10n.noMatches, style: const TextStyle(color: Colors.black54)),
                      )
                    : ListView.builder(
                        itemCount: displayed.length,
                        itemBuilder: (context, i) {
                          final p = displayed[i];
                          final imageUrl = AppConfig.resourceUrl(p.imageResourceId);
                          return ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imageUrl == null
                                  ? const Icon(Icons.inventory_2_outlined, color: Colors.black26)
                                  : Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.inventory_2_outlined, color: Colors.black26),
                                    ),
                            ),
                            title: Text(p.label(lang)),
                            subtitle: Text(p.barcode),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                              onPressed: () => _pickProduct(p),
                            ),
                            onTap: () => _pickProduct(p),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: visit.busy ? null : _cancelVisit,
                  // FittedBox + maxLines:1 guarantees a single line that
                  // shrinks to fit instead of wrapping — "Cancel Visit" was
                  // wrapping to two lines while "End Visit" didn't, since
                  // the round button between them eats a fixed chunk of
                  // width (human lead, 2026-09-09).
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.cancelVisit, maxLines: 1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                        backgroundColor: opColor,
                      ),
                      onPressed: _openStagedItems,
                      child: Icon(opIcon, color: Colors.white),
                    ),
                    if (_staged.isNotEmpty)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            '${_staged.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: visit.busy ? null : _endVisit,
                  child: visit.busy
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(l10n.endVisit, maxLines: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
