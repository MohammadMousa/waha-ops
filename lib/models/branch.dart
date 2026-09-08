class Branch {
  final int id;
  final String name;
  final String? displayName;

  const Branch({required this.id, required this.name, this.displayName});

  String get label => displayName ?? name;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        displayName: json['displayName'] as String?,
      );
}
