// lib/providers/app_provider.dart
// Central state management using Provider (ChangeNotifier)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/hash_service.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';

enum UserRole { none, user, admin }

class AppProvider extends ChangeNotifier {
  // ─── Persisted config ────────────────────────────────────────────────────
  String _spreadsheetId = '';
  String _webAppUrl = '';

  String get spreadsheetId => _spreadsheetId;
  String get webAppUrl => _webAppUrl;
  bool get isConfigured => _spreadsheetId.isNotEmpty && _webAppUrl.isNotEmpty;

  // ─── Admin credentials (default: admin@gmail.com / admin) ────────────────
  static const String defaultAdminEmail = 'admin@gmail.com';
  static const String defaultAdminPassword = 'admin';

  String _adminEmail = defaultAdminEmail;
  String _adminPassword = defaultAdminPassword;
  String _adminProfileImagePath = '';
  String _adminVillageCode = '';

  String get adminEmail => _adminEmail;
  String get adminPassword => _adminPassword;
  String get adminProfileImagePath => _adminProfileImagePath;
  String get adminVillageCode => _adminVillageCode;

  /// Returns true if the admin is using factory default credentials
  bool get isUsingDefaultAdminCredentials =>
      _adminEmail == defaultAdminEmail &&
      _adminPassword == defaultAdminPassword;

  // ─── Auth state ───────────────────────────────────────────────────────────
  UserModel? _currentUser;
  UserRole _role = UserRole.none;
  bool _isLoggedIn = false;
  String _lastLoggedInGmail = '';
  String _pinHash = '';

  UserModel? get currentUser => _currentUser;
  UserRole get role => _role;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _role == UserRole.admin;
  String get lastLoggedInGmail => _lastLoggedInGmail;
  bool get hasPin => _pinHash.isNotEmpty;

  // ─── Loading / Error ──────────────────────────────────────────────────────
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ─── Initialise ───────────────────────────────────────────────────────────

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _spreadsheetId = prefs.getString('spreadsheet_id') ?? '';
    _webAppUrl = prefs.getString('web_app_url') ?? '';
    _adminEmail = prefs.getString('admin_email') ?? defaultAdminEmail;
    _adminPassword = prefs.getString('admin_password') ?? defaultAdminPassword;
    _adminProfileImagePath = prefs.getString('admin_profile_image') ?? '';
    _adminVillageCode = prefs.getString('admin_village_code') ?? '';
    _lastLoggedInGmail = prefs.getString('last_gmail') ?? '';
    _pinHash = prefs.getString('pin_hash') ?? '';

    // Also load from Local Database (app_config table)
    try {
      final dbSpreadsheetId = await DatabaseHelper.instance.getConfig(
        'spreadsheet_id',
      );
      final dbWebAppUrl = await DatabaseHelper.instance.getConfig(
        'web_app_url',
      );
      final dbVillageCode = await DatabaseHelper.instance.getConfig(
        'admin_village_code',
      );

      // Use database values if SharedPreferences is empty
      if (_spreadsheetId.isEmpty && dbSpreadsheetId != null) {
        _spreadsheetId = dbSpreadsheetId;
      }
      if (_webAppUrl.isEmpty && dbWebAppUrl != null) {
        _webAppUrl = dbWebAppUrl;
      }
      if (_adminVillageCode.isEmpty && dbVillageCode != null) {
        _adminVillageCode = dbVillageCode;
      }
    } catch (e) {
      debugPrint('Error loading config from database: $e');
    }

    // Start auto-sync if configured
    if (_webAppUrl.isNotEmpty) {
      SyncService.instance.startAutoSync(
        _webAppUrl,
        interval: const Duration(minutes: 1),
      );
      debugPrint('✓ Auto-sync enabled');
    }

    notifyListeners();
  }

  // ─── Config (Sheet setup) ─────────────────────────────────────────────────

  Future<void> saveConfig({
    required String spreadsheetId,
    required String webAppUrl,
  }) async {
    _spreadsheetId = spreadsheetId;
    _webAppUrl = webAppUrl;

    // Auto-generate village code from spreadsheet ID (first 8 characters)
    if (spreadsheetId.isNotEmpty) {
      _adminVillageCode = spreadsheetId
          .substring(0, spreadsheetId.length > 8 ? 8 : spreadsheetId.length)
          .toUpperCase();
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spreadsheet_id', spreadsheetId);
    await prefs.setString('web_app_url', webAppUrl);
    await prefs.setString('admin_village_code', _adminVillageCode);

    // Save to Local Database (app_config table)
    try {
      await DatabaseHelper.instance.setConfig('spreadsheet_id', spreadsheetId);
      await DatabaseHelper.instance.setConfig('web_app_url', webAppUrl);
      await DatabaseHelper.instance.setConfig(
        'admin_village_code',
        _adminVillageCode,
      );
      debugPrint('✓ Config saved to Local Database');
    } catch (e) {
      debugPrint('Error saving config to database: $e');
    }

    notifyListeners();
  }

  // ─── Admin credentials change ─────────────────────────────────────────────

  /// Returns true if [email]+[password] match the stored admin credentials
  bool checkAdminCredentials(String email, String password) {
    return email.trim().toLowerCase() == _adminEmail.toLowerCase() &&
        password == _adminPassword;
  }

  Future<void> saveAdminCredentials({
    required String newEmail,
    required String newPassword,
    String? newVillageCode,
  }) async {
    _adminEmail = newEmail.trim().toLowerCase();
    _adminPassword = newPassword;
    if (newVillageCode != null) {
      _adminVillageCode = newVillageCode.trim();
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_email', _adminEmail);
    await prefs.setString('admin_password', _adminPassword);
    if (newVillageCode != null) {
      await prefs.setString('admin_village_code', _adminVillageCode);
    }

    // Save village code to Local Database
    if (newVillageCode != null) {
      try {
        await DatabaseHelper.instance.setConfig(
          'admin_village_code',
          _adminVillageCode,
        );
      } catch (e) {
        debugPrint('Error saving village code to database: $e');
      }
    }

    notifyListeners();
  }

  Future<void> saveAdminProfileImage(String path) async {
    _adminProfileImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_profile_image', path);
    notifyListeners();
  }

  /// Extract spreadsheet ID from a Google Sheets URL
  static String? extractSpreadsheetId(String url) {
    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void loginAs(UserModel user) {
    _currentUser = user;
    _isLoggedIn = true;
    _role = user.status == 'Admin' ? UserRole.admin : UserRole.user;
    _persistSession(user.gmail);
    notifyListeners();
  }

  void loginAsAdmin(String email) {
    // Create a synthetic UserModel for admin session
    _currentUser = UserModel(
      name: 'Admin',
      gmail: email,
      address: '',
      lat: 0,
      lng: 0,
      status: 'Admin',
    );
    _isLoggedIn = true;
    _role = UserRole.admin;
    _persistSession(email);
    notifyListeners();
  }

  Future<void> _persistSession(String gmail) async {
    _lastLoggedInGmail = gmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_gmail', gmail);
  }

  Future<void> savePin(String pin) async {
    final hash = HashService.hashPassword(pin);
    _pinHash = hash;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin_hash', hash);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (_pinHash.isEmpty) return false;
    return HashService.verify(pin, _pinHash);
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    _role = UserRole.none;
    _errorMessage = '';
    _lastLoggedInGmail = '';

    // Stop auto-sync on logout
    SyncService.instance.stopAutoSync();

    // Optional: decided to keep PIN even after logout for convenience,
    // but clear the active session Gmail so user must re-auth by Pass if they logout.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_gmail');
    notifyListeners();
  }

  /// Update cached current user status (after admin approves)
  void updateCurrentUserStatus(String status) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(status: status);
      if (status == 'Admin') _role = UserRole.admin;
      notifyListeners();
    }
  }
}
