// lib/services/sync_service.dart
// Real-time sync service between Google Sheets and Local Database

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'sheets_service.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  Timer? _syncTimer;
  bool _isSyncing = false;
  String? _webAppUrl;

  /// Initialize auto-sync with periodic interval
  void startAutoSync(
    String webAppUrl, {
    Duration interval = const Duration(minutes: 1),
  }) {
    _webAppUrl = webAppUrl;

    // Cancel existing timer
    _syncTimer?.cancel();

    // Start periodic sync
    _syncTimer = Timer.periodic(interval, (_) {
      syncAll();
    });

    debugPrint('✓ Auto-sync started (interval: ${interval.inMinutes} minutes)');
  }

  /// Stop auto-sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('✓ Auto-sync stopped');
  }

  /// Sync all data between Google Sheets and Local Database
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress, skipping...');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (_webAppUrl == null || _webAppUrl!.isEmpty) {
      debugPrint('⚠️ Web App URL not configured');
      return SyncResult(success: false, message: 'Web App URL not configured');
    }

    _isSyncing = true;
    debugPrint('🔄 Starting sync...');

    try {
      // 1. Sync Users from Sheets to Local DB
      final usersResult = await _syncUsersFromSheets();

      // 2. Sync Admins from Sheets to Local DB
      final adminsResult = await _syncAdminsFromSheets();

      // 3. Sync pending local changes to Sheets
      final pendingResult = await _syncPendingToSheets();

      _isSyncing = false;

      final totalSynced =
          usersResult.count + adminsResult.count + pendingResult.count;
      debugPrint('✅ Sync completed: $totalSynced items synced');

      return SyncResult(
        success: true,
        message: 'Synced $totalSynced items',
        usersSynced: usersResult.count,
        pendingSynced: pendingResult.count,
      );
    } catch (e) {
      _isSyncing = false;
      debugPrint('❌ Sync failed: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    }
  }

  /// Sync users from Google Sheets to Local Database
  Future<_SyncCount> _syncUsersFromSheets() async {
    try {
      debugPrint('🔄 Syncing users from Sheets...');

      // Fetch all users from Sheets
      final sheetUsers = await SheetsService.instance.fetchAllMembers(
        _webAppUrl!,
      );

      debugPrint('📊 Fetched ${sheetUsers.length} users from Sheets');

      if (sheetUsers.isEmpty) {
        debugPrint('ℹ️ No users in Sheets');
        return _SyncCount(0);
      }

      int syncedCount = 0;

      for (final sheetUser in sheetUsers) {
        try {
          final gmail = sheetUser['Gmail']?.toString();
          if (gmail == null || gmail.isEmpty) {
            debugPrint('  ⚠️ Skipping user with empty Gmail');
            continue;
          }

          // Check if user exists in local DB
          final localUser = await DatabaseHelper.instance.getUserByGmail(gmail);

          final userModel = UserModel(
            name: sheetUser['Name']?.toString() ?? '',
            gmail: gmail,
            address: sheetUser['Address']?.toString() ?? '',
            villageCode: sheetUser['VillageCode']?.toString() ?? '',
            passwordHash: sheetUser['PasswordHash']?.toString() ?? '',
            lat: _parseDouble(sheetUser['Latitude']),
            lng: _parseDouble(sheetUser['Longitude']),
            status: sheetUser['Status']?.toString() ?? 'Pending',
          );

          if (localUser == null) {
            // Insert new user
            await DatabaseHelper.instance.insertUser(userModel);
            syncedCount++;
            debugPrint('  ➕ Added: $gmail (${userModel.status})');
          } else {
            // Update existing user if status changed
            if (localUser.status != userModel.status) {
              await DatabaseHelper.instance.updateUserStatus(
                gmail,
                userModel.status,
              );
              syncedCount++;
              debugPrint(
                '  🔄 Updated: $gmail (${localUser.status} → ${userModel.status})',
              );
            } else {
              debugPrint('  ✓ No change: $gmail (${userModel.status})');
            }
          }
        } catch (e) {
          debugPrint('  ⚠️ Error syncing user: $e');
        }
      }

      debugPrint('✓ Users synced from Sheets: $syncedCount');
      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Error syncing users from Sheets: $e');
      return _SyncCount(0);
    }
  }

  /// Sync pending local changes to Google Sheets
  Future<_SyncCount> _syncPendingToSheets() async {
    try {
      await SheetsService.instance.retrySync(_webAppUrl!);

      // Get remaining items in queue
      final remaining = await DatabaseHelper.instance.getAllSyncItems();
      final syncedCount = remaining.isEmpty ? 0 : remaining.length;

      if (syncedCount > 0) {
        debugPrint('✓ Pending items synced to Sheets: $syncedCount');
      }

      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Error syncing pending to Sheets: $e');
      return _SyncCount(0);
    }
  }

  /// Sync admins from Google Sheets to Local Database
  Future<_SyncCount> _syncAdminsFromSheets() async {
    try {
      // Fetch all admins from Sheets
      final sheetAdmins = await SheetsService.instance.fetchAllAdmins(
        _webAppUrl!,
      );

      if (sheetAdmins.isEmpty) {
        debugPrint('ℹ️ No admins in Sheets');
        return _SyncCount(0);
      }

      int syncedCount = 0;

      for (final sheetAdmin in sheetAdmins) {
        try {
          final gmail = sheetAdmin['Gmail']?.toString();
          if (gmail == null || gmail.isEmpty) continue;

          // Check if admin exists in local DB
          final localAdmin = await DatabaseHelper.instance.getAdminByGmail(
            gmail,
          );

          if (localAdmin == null) {
            // Insert new admin
            await DatabaseHelper.instance.insertAdmin(sheetAdmin);
            syncedCount++;
            debugPrint('  ➕ Added admin: $gmail');
          }
          // Note: Admins don't have status updates like users
        } catch (e) {
          debugPrint('  ⚠️ Error syncing admin: $e');
        }
      }

      debugPrint('✓ Admins synced from Sheets: $syncedCount');
      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Error syncing admins from Sheets: $e');
      return _SyncCount(0);
    }
  }

  /// Manual sync trigger (for pull-to-refresh)
  Future<SyncResult> manualSync(String webAppUrl) async {
    _webAppUrl = webAppUrl;
    return await syncAll();
  }

  /// Sync single user immediately after registration
  Future<bool> syncUserImmediately(String webAppUrl, UserModel user) async {
    try {
      final success = await SheetsService.instance.registerMember(
        webAppUrl,
        user,
      );

      if (success) {
        debugPrint('✓ User synced immediately: ${user.gmail}');
        return true;
      } else {
        debugPrint('⚠️ User queued for later sync: ${user.gmail}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error syncing user immediately: $e');
      return false;
    }
  }

  /// Helper to parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}

/// Sync result model
class SyncResult {
  final bool success;
  final String message;
  final int usersSynced;
  final int pendingSynced;

  SyncResult({
    required this.success,
    required this.message,
    this.usersSynced = 0,
    this.pendingSynced = 0,
  });

  int get totalSynced => usersSynced + pendingSynced;
}

/// Internal sync count helper
class _SyncCount {
  final int count;
  _SyncCount(this.count);
}
