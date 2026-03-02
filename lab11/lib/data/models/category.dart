class Category {
  final int? id;
  final String name;
  final String colorHex;
  final String iconKey;
  final String? createdAt;
  final String? updatedAt;

  Category({
    this.id,
    required this.name,
    required this.colorHex,
    required this.iconKey,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_key': iconKey,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      colorHex: map['color_hex'],
      iconKey: map['icon_key'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? iconKey,
    String? createdAt,
    String? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
