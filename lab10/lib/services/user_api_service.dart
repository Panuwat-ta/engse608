import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserApiService {
  static const String _baseUrl = 'https://fakestoreapi.com/users';

  Future<List<UserModel>> fetchUsers() async {
    final res = await http.get(Uri.parse(_baseUrl));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load users (${res.statusCode})');
  }

  Future<UserModel> fetchUserById(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/$id'));
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load user ($id) (${res.statusCode})');
  }

  Future<UserModel> createUser(UserModel user) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    // FakeStoreAPI คืนค่า 200/201 (ขึ้นกับระบบ)
    if (res.statusCode == 200 || res.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to create user (${res.statusCode})');
  }

  Future<UserModel> updateUser(int id, UserModel user) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to update user ($id) (${res.statusCode})');
  }

  Future<void> deleteUser(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (res.statusCode == 200) return;
    throw Exception('Failed to delete user ($id) (${res.statusCode})');
  }
}
