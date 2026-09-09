// GET /api/categories?storeId= — per to_Frontend_AI_On_Inventory_Task [10].
class Category {
  final int id;
  final Map<String, dynamic> name;

  const Category({required this.id, required this.name});

  String label([String languageCode = 'en']) =>
      name[languageCode] as String? ?? name['en'] as String? ?? '';

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as Map<String, dynamic>?) ?? {},
      );
}
