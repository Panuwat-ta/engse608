// lib/models/user_model.dart
// Model for a registered community member

class UserModel {
  final int? id;
  final String name;
  final String gmail;
  final String address;
  final String villageCode;
  final String passwordHash; // SHA-256 hashed password
  final double lat;
  final double lng;
  final String status; // 'Pending', 'Active', 'Admin'

  const UserModel({
    this.id,
    required this.name,
    required this.gmail,
    required this.address,
    this.villageCode = '',
    this.passwordHash = '',
    required this.lat,
    required this.lng,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'gmail': gmail,
      'address': address,
      'village_code': villageCode,
      'password_hash': passwordHash,
      'lat': lat,
      'lng': lng,
      'status': status,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      gmail: map['gmail'] as String,
      address: map['address'] as String,
      villageCode: map['village_code'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      status: map['status'] as String? ?? 'Pending',
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? gmail,
    String? address,
    String? villageCode,
    String? passwordHash,
    double? lat,
    double? lng,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gmail: gmail ?? this.gmail,
      address: address ?? this.address,
      villageCode: villageCode ?? this.villageCode,
      passwordHash: passwordHash ?? this.passwordHash,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
    );
  }

  /// Headers list sent to Google Apps Script on first-time setup
  static const List<String> headers = [
    'Name',
    'Gmail',
    'Address',
    'VillageCode',
    'PasswordHash',
    'Latitude',
    'Longitude',
    'Status',
    'RegisteredAt',
  ];

  /// Converts this model to a row of values (matching headers order)
  List<dynamic> toSheetRow() {
    // Convert to Thailand time (GMT+7)
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final thailandTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return [
      name,
      gmail,
      address,
      villageCode,
      passwordHash,
      lat,
      lng,
      status,
      thailandTime,
    ];
  }

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, gmail: $gmail, status: $status)';
}
