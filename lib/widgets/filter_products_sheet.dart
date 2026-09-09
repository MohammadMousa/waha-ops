import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/category.dart';

// Result of the filter sheet — null means dismissed without applying.
// Tags from the Visit|Products FilterX.jpeg reference is deliberately NOT
// included: per the backend's own Product.java doc comment, tags are only
// populated on the single-product detail endpoint, always empty on the
// browse/search lists this screen actually uses — a tag filter here would
// be filtering against data that's never there. See
// ~/git/to_Backend_AI_On_Inventory_Task [14.3] follow-up.
class ProductFilter {
  final String name;
  final String barcode;
  final int? categoryId;
  final String descriptionKeyword;
  final bool inStockOnly;
  const ProductFilter({
    this.name = '',
    this.barcode = '',
    this.categoryId,
    this.descriptionKeyword = '',
    this.inStockOnly = false,
  });
}

Future<ProductFilter?> showFilterProductsSheet(
  BuildContext context, {
  required ProductFilter current,
  required List<Category> categories,
  required String languageCode,
}) {
  return showModalBottomSheet<ProductFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _FilterProductsSheet(current: current, categories: categories, languageCode: languageCode),
  );
}

class _FilterProductsSheet extends StatefulWidget {
  final ProductFilter current;
  final List<Category> categories;
  final String languageCode;
  const _FilterProductsSheet({
    required this.current,
    required this.categories,
    required this.languageCode,
  });

  @override
  State<_FilterProductsSheet> createState() => _FilterProductsSheetState();
}

class _FilterProductsSheetState extends State<_FilterProductsSheet> {
  late final _name = TextEditingController(text: widget.current.name);
  late final _barcode = TextEditingController(text: widget.current.barcode);
  late final _description = TextEditingController(text: widget.current.descriptionKeyword);
  late bool _inStockOnly = widget.current.inStockOnly;
  late int? _categoryId = widget.current.categoryId;

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _description.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop(ProductFilter(
      name: _name.text.trim(),
      barcode: _barcode.text.trim(),
      categoryId: _categoryId,
      descriptionKeyword: _description.text.trim(),
      inStockOnly: _inStockOnly,
    ));
  }

  void _clearAll() {
    Navigator.of(context).pop(const ProductFilter());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.filterProductsTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.productNameLabel,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 4),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  hintText: l10n.enterProductName,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.barcodeLabel, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 4),
              TextField(
                controller: _barcode,
                decoration: InputDecoration(
                  hintText: l10n.enterOrScanBarcode,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: const Icon(Icons.qr_code_scanner),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.categoryLabel, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 4),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(l10n.allCategoriesLabel)),
                  ...widget.categories.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.label(widget.languageCode)),
                      )),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              Text(l10n.descriptionKeywordLabel,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 4),
              TextField(
                controller: _description,
                decoration: InputDecoration(
                  hintText: l10n.descriptionKeywordLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              FilterChip(
                label: Text(l10n.inStockOnly),
                selected: _inStockOnly,
                onSelected: (v) => setState(() => _inStockOnly = v),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
                      onPressed: _clearAll,
                      child: Text(l10n.clearAllButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(onPressed: _apply, child: Text(l10n.applyFiltersButton)),
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
