class UserModel {
  final int? id;
  final String email;
  final String username;
  final String password;
  final NameModel name;
  final AddressModel address;
  final String phone;

  UserModel({
    this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      name: NameModel.fromJson(json['name'] ?? {}),
      address: AddressModel.fromJson(json['address'] ?? {}),
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // API ใช้ส่งข้อมูลแนม nested object
    return {
      if (id != null) 'id': id,
      'email': email,
      'username': username,
      'password': password,
      'name': name.toJson(),
      'address': address.toJson(),
      'phone': phone,
    };
  }
}

class NameModel {
  final String firstname;
  final String lastname;

  NameModel({required this.firstname, required this.lastname});

  factory NameModel.fromJson(Map<String, dynamic> json) {
    return NameModel(
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'firstname': firstname,
    'lastname': lastname,
  };
}

class AddressModel {
  final String city;
  final String street;
  final int number;
  final String zipcode;
  final GeoLocationModel geolocation;

  AddressModel({
    required this.city,
    required this.street,
    required this.number,
    required this.zipcode,
    required this.geolocation,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      number: (json['number'] is num) ? (json['number'] as num).toInt() : 0,
      zipcode: json['zipcode'] ?? '',
      geolocation: GeoLocationModel.fromJson(json['geolocation'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'street': street,
    'number': number,
    'zipcode': zipcode,
    'geolocation': geolocation.toJson(),
  };
}

class GeoLocationModel {
  final String lat;
  final String long;

  GeoLocationModel({required this.lat, required this.long});

  factory GeoLocationModel.fromJson(Map<String, dynamic> json) {
    return GeoLocationModel(
      lat: (json['lat'] ?? '').toString(),
      long: (json['long'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'long': long};
}
