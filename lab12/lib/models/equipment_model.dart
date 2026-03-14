// lib/models/equipment_model.dart
// Model for equipment/tools

class EquipmentModel {
  final int? id;
  final String name;
  final String description;
  final String category;
  final int quantity;
  final int available;
  final String status; // 'Available', 'Unavailable', 'Maintenance'
  final String createdAt;

  EquipmentModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.quantity,
    required this.available,
    this.status = 'Available',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'available': available,
      'status': status,
      'created_at': createdAt,
    };
  }

  // Create from Map
  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    return EquipmentModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      quantity: map['quantity'] as int,
      available: map['available'] as int,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  // Convert to Sheet row
  List<dynamic> toSheetRow() {
    return [
      id ?? '',
      name,
      description,
      category,
      quantity,
      available,
      status,
      createdAt,
    ];
  }

  // Headers for Google Sheets
  static List<String> get headers => [
    'ID',
    'Name',
    'Description',
    'Category',
    'Quantity',
    'Available',
    'Status',
    'CreatedAt',
  ];

  EquipmentModel copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    int? quantity,
    int? available,
    String? status,
    String? createdAt,
  }) {
    return EquipmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      available: available ?? this.available,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
