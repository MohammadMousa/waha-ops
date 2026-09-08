// Minimal product shape for inventory operation item selection.
// Mirrors the fields Product.fromJson reads in waha_platform's model,
// trimmed to what the visit workflow needs.
class ProductLite {
  final int id;
  final String barcode;
  final Map<String, dynamic> name;

  const ProductLite({required this.id, required this.barcode, required this.name});

  String label([String languageCode = 'en']) =>
      name[languageCode] as String? ?? name['en'] as String? ?? barcode;

  factory ProductLite.fromJson(Map<String, dynamic> json) => ProductLite(
        id: (json['id'] as num).toInt(),
        barcode: json['barcode'] as String? ?? '',
        name: (json['name'] as Map<String, dynamic>?) ?? {},
      );
}
