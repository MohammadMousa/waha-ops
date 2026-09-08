class Branch {
  final int id;
  final String name;
  final Map<String, String>? displayName; // e.g. {"en": "EPC Bank", "ar": "بنك ايبك"}

  const Branch({required this.id, required this.name, this.displayName});

  // Falls back to `name` (the technical slug) only when the backend
  // hasn't sent displayName yet — see to_Backend_AI_On_Inventory_Task:
  // the branch-list endpoints currently return {id, name} only, even
  // though stores.display_name already has real localized values.
  String label(String languageCode) =>
      displayName?[languageCode] ?? displayName?['en'] ?? name;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        displayName: (json['displayName'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())),
      );
}
