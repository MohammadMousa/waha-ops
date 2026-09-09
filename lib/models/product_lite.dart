// Minimal product shape for inventory operation item selection.
// Mirrors the fields Product.fromJson reads in waha_platform's model,
// trimmed to what the visit workflow needs. categoryId/description/
// imageResourceId added per to_Frontend_AI_On_Inventory_Task [10]
// (2026-09-09) — present on both browse and search responses. `tags` is
// deliberately NOT included here: per the backend's own Product.java doc
// comment, tags are only populated on the single-product detail endpoint,
// always empty on the list/search endpoints this app actually uses — a
// tag filter over the browse list would just be filtering against nothing.
class ProductLite {
  final int id;
  final String barcode;
  final Map<String, dynamic> name;
  final Map<String, dynamic>? description;
  final int? categoryId;
  final int? imageResourceId;

  const ProductLite({
    required this.id,
    required this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.imageResourceId,
  });

  String label([String languageCode = 'en']) =>
      name[languageCode] as String? ?? name['en'] as String? ?? barcode;

  String descriptionText([String languageCode = 'en']) =>
      description?[languageCode] as String? ?? description?['en'] as String? ?? '';

  factory ProductLite.fromJson(Map<String, dynamic> json) => ProductLite(
        id: (json['id'] as num).toInt(),
        barcode: json['barcode'] as String? ?? '',
        name: (json['name'] as Map<String, dynamic>?) ?? {},
        description: json['description'] as Map<String, dynamic>?,
        categoryId: (json['categoryId'] as num?)?.toInt(),
        imageResourceId: (json['imageResourceId'] as num?)?.toInt(),
      );
}
