import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_api_service.dart';

class UserProvider extends ChangeNotifier {
  final UserApiService _api = UserApiService();
  List<UserModel> users = [];
  bool isLoading = false;
  String? error;

  Future<void> loadUsers() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString('users_data');

      if (usersJson != null && usersJson.isNotEmpty) {
        // Load from local storage
        final List<dynamic> jsonList = json.decode(usersJson);
        users = jsonList.map((json) => UserModel.fromJson(json)).toList();
      } else {
        // Load from API and save to local
        users = await _api.fetchUsers();
        await _saveToPrefs();
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String usersJson = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString('users_data', usersJson);
  }

  Future<void> addUser(UserModel newUser) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
      final newId = users.isEmpty
          ? 1
          : (users.map((u) => u.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);

      final created = UserModel(
        id: newId,
        email: newUser.email,
        username: newUser.username,
        password: newUser.password,
        name: newUser.name,
        address: newUser.address,
        phone: newUser.phone,
      );
      users.insert(0, created);
      await _saveToPrefs();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> editUser(int id, UserModel updatedUser) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
      final index = users.indexWhere((u) => u.id == id);
      if (index != -1) {
        users[index] = UserModel(
          id: id,
          email: updatedUser.email,
          username: updatedUser.username,
          password: updatedUser.password,
          name: updatedUser.name,
          address: updatedUser.address,
          phone: updatedUser.phone,
        );
        await _saveToPrefs();
      }
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> removeUser(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // For local storage, we don't necessarily need to call the API delete
      // if we are treating local as truth. But if we want to sync, we might.
      // Given the requirement "save to local", I will prioritize local update.
      // await _api.deleteUser(id); // Optional: keep/remove based on sync needs

      users.removeWhere((u) => u.id == id);
      await _saveToPrefs();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
