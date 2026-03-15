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

  /// Map Thai headers from Google Sheets to English keys for local processing
  static Map<String, dynamic> _mapSheetToLocal(Map<String, dynamic> sheetData) {
    final mapped = <String, dynamic>{};

    // User mappings
    if (sheetData.containsKey('ชื่อ')) {
      mapped['Name'] = sheetData['ชื่อ'];
    }
    if (sheetData.containsKey('อีเมล')) {
      mapped['Gmail'] = sheetData['อีเมล'];
    }
    if (sheetData.containsKey('ที่อยู่')) {
      mapped['Address'] = sheetData['ที่อยู่'];
    }
    if (sheetData.containsKey('รหัสหมู่บ้าน')) {
      mapped['VillageCode'] = sheetData['รหัสหมู่บ้าน'];
    }
    if (sheetData.containsKey('รหัสผ่าน')) {
      mapped['PasswordHash'] = sheetData['รหัสผ่าน'];
    }
    if (sheetData.containsKey('ละติจูด')) {
      mapped['Latitude'] = sheetData['ละติจูด'];
    }
    if (sheetData.containsKey('ลองจิจูด')) {
      mapped['Longitude'] = sheetData['ลองจิจูด'];
    }
    if (sheetData.containsKey('สถานะ')) {
      mapped['Status'] = sheetData['สถานะ'];
    }
    if (sheetData.containsKey('วันที่สมัคร')) {
      mapped['RegisteredAt'] = sheetData['วันที่สมัคร'];
    }

    // Equipment mappings
    if (sheetData.containsKey('ID')) {
      mapped['ID'] = sheetData['ID'];
    }
    if (sheetData.containsKey('ชื่อ')) {
      mapped['Name'] = sheetData['ชื่อ'];
    }
    if (sheetData.containsKey('รายละเอียด')) {
      mapped['Description'] = sheetData['รายละเอียด'];
    }
    if (sheetData.containsKey('หมวดหมู่')) {
      mapped['Category'] = sheetData['หมวดหมู่'];
    }
    if (sheetData.containsKey('จำนวนทั้งหมด')) {
      mapped['Quantity'] = sheetData['จำนวนทั้งหมด'];
    }
    if (sheetData.containsKey('จำนวนที่ว่าง')) {
      mapped['Available'] = sheetData['จำนวนที่ว่าง'];
    }
    if (sheetData.containsKey('วันที่สร้าง')) {
      mapped['CreatedAt'] = sheetData['วันที่สร้าง'];
    }
    if (sheetData.containsKey('วันที่อัปเดต')) {
      mapped['UpdatedAt'] = sheetData['วันที่อัปเดต'];
    }

    // Admin mappings
    if (sheetData.containsKey('บทบาท')) {
      mapped['Role'] = sheetData['บทบาท'];
    }
    if (sheetData.containsKey('วันที่สร้าง')) {
      mapped['CreatedAt'] = sheetData['วันที่สร้าง'];
    }

    // Transaction mappings
    if (sheetData.containsKey('ID')) {
      mapped['ID'] = sheetData['ID'];
    }
    if (sheetData.containsKey('EquipmentID')) {
      mapped['EquipmentID'] = sheetData['EquipmentID'];
    }
    if (sheetData.containsKey('อีเมลผู้ใช้')) {
      mapped['UserGmail'] = sheetData['อีเมลผู้ใช้'];
    }
    if (sheetData.containsKey('วันที่ยืม')) {
      mapped['BorrowDate'] = sheetData['วันที่ยืม'];
    }
    if (sheetData.containsKey('วันที่ต้องคืน')) {
      mapped['ReturnDate'] = sheetData['วันที่ต้องคืน'];
    }
    if (sheetData.containsKey('วันที่คืนจริง')) {
      mapped['ActualReturnDate'] = sheetData['วันที่คืนจริง'];
    }
    if (sheetData.containsKey('สถานะ')) {
      mapped['Status'] = sheetData['สถานะ'];
    }
    if (sheetData.containsKey('หมายเหตุ')) {
      mapped['Notes'] = sheetData['หมายเหตุ'];
    }

    // Return mappings
    if (sheetData.containsKey('ID')) {
      mapped['ID'] = sheetData['ID']; // This is the transaction ID
    }
    if (sheetData.containsKey('EquipmentID')) {
      mapped['EquipmentID'] = sheetData['EquipmentID'];
    }
    if (sheetData.containsKey('ชื่ออุปกรณ์')) {
      mapped['EquipmentName'] = sheetData['ชื่ออุปกรณ์'];
    }
    if (sheetData.containsKey('อีเมลผู้ใช้')) {
      mapped['UserGmail'] = sheetData['อีเมลผู้ใช้'];
    }
    if (sheetData.containsKey('ชื่อผู้ใช้')) {
      mapped['UserName'] = sheetData['ชื่อผู้ใช้'];
    }
    if (sheetData.containsKey('วันที่ยืม')) {
      mapped['BorrowDate'] = sheetData['วันที่ยืม'];
    }
    if (sheetData.containsKey('วันที่ต้องคืน')) {
      mapped['ReturnDate'] = sheetData['วันที่ต้องคืน'];
    }
    if (sheetData.containsKey('วันที่คืนจริง')) {
      mapped['ActualReturnDate'] = sheetData['วันที่คืนจริง'];
    }
    if (sheetData.containsKey('เกินกำหนด')) {
      mapped['Overdue'] = sheetData['เกินกำหนด'];
    }
    if (sheetData.containsKey('หมายเหตุ')) {
      mapped['Notes'] = sheetData['หมายเหตุ'];
    }
    if (sheetData.containsKey('อนุมัติโดย')) {
      mapped['ApprovedBy'] = sheetData['อนุมัติโดย'];
    }
    if (sheetData.containsKey('วันที่อนุมัติ')) {
      mapped['ApprovedAt'] = sheetData['วันที่อนุมัติ'];
    }
    if (sheetData.containsKey('วันที่บันทึก')) {
      mapped['RecordedAt'] = sheetData['วันที่บันทึก'];
    }

    // Copy any unmapped fields as-is
    for (final entry in sheetData.entries) {
      if (!mapped.containsKey(entry.key) && !_isThaiHeader(entry.key)) {
        mapped[entry.key] = entry.value;
      }
    }

    return mapped;
  }

  /// Check if a header is in Thai (to avoid copying Thai headers to mapped data)
  static bool _isThaiHeader(String header) {
    const thaiHeaders = [
      'ชื่อ',
      'อีเมล',
      'ที่อยู่',
      'รหัสหมู่บ้าน',
      'รหัสผ่าน',
      'ละติจูด',
      'ลองจิจูด',
      'สถานะ',
      'วันที่สมัคร',
      'รายละเอียด',
      'หมวดหมู่',
      'จำนวนทั้งหมด',
      'จำนวนที่ว่าง',
      'วันที่สร้าง',
      'วันที่อัปเดต',
      'บทบาท',
      'ชื่ออุปกรณ์',
      'อีเมลผู้ใช้',
      'ชื่อผู้ใช้',
      'วันที่ยืม',
      'วันที่ต้องคืน',
      'วันที่คืนจริง',
      'เกินกำหนด',
      'หมายเหตุ',
      'อนุมัติโดย',
      'วันที่อนุมัติ',
      'วันที่บันทึก',
    ];
    return thaiHeaders.contains(header);
  }

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
    // Check if already syncing
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress, skipping...');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    // Check if URL is configured
    if (_webAppUrl == null || _webAppUrl!.isEmpty) {
      debugPrint('⚠️ Web App URL not configured');
      return SyncResult(success: false, message: 'Web App URL not configured');
    }

    // Set sync flag
    _isSyncing = true;
    debugPrint('🔄 Starting sync...');

    try {
      // Add timeout to prevent hanging
      return await Future.any([
        _performSync(),
        Future.delayed(
          const Duration(seconds: 30),
          () => SyncResult(
            success: false,
            message: 'Sync timeout after 30 seconds',
          ),
        ),
      ]);
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    } finally {
      // Always reset sync flag, even if error occurs
      _isSyncing = false;
      debugPrint('🔓 Sync lock released');
    }
  }

  /// Perform the actual sync operations
  Future<SyncResult> _performSync() async {
    try {
      // 1. Sync unsynced local equipment to Sheets (Local → Sheets)
      final unsyncedResult = await _syncUnsyncedEquipmentToSheets();

      // 2. Sync Users from Sheets to Local DB
      final usersResult = await _syncUsersFromSheets();

      // 3. Sync Admins from Sheets to Local DB
      final adminsResult = await _syncAdminsFromSheets();

      // 4. Sync Equipment from Sheets to Local DB
      final equipmentResult = await _syncEquipmentFromSheets();

      // 5. Sync Transactions from Sheets to Local DB
      final transactionsFromSheetsResult = await _syncTransactionsFromSheets();

      // 6. Sync Transactions from Local DB to Sheets
      final transactionsToSheetsResult = await _syncTransactionsToSheets();

      // 6. Sync pending local changes to Sheets
      final pendingResult = await _syncPendingToSheets();

      final totalSynced =
          usersResult.count +
          adminsResult.count +
          equipmentResult.count +
          transactionsFromSheetsResult.count +
          transactionsToSheetsResult.count +
          pendingResult.count +
          unsyncedResult.count;
      debugPrint('✅ Sync completed: $totalSynced items synced');

      return SyncResult(
        success: true,
        message: 'Synced $totalSynced items',
        usersSynced: usersResult.count,
        adminsSynced: adminsResult.count,
        equipmentSynced: equipmentResult.count + unsyncedResult.count,
        transactionsSynced:
            transactionsFromSheetsResult.count +
            transactionsToSheetsResult.count,
        pendingSynced: pendingResult.count,
      );
    } catch (e) {
      debugPrint('❌ Sync operation failed: $e');
      rethrow;
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
          final mappedUser = _mapSheetToLocal(sheetUser);
          final gmail = mappedUser['Gmail']?.toString();
          if (gmail == null || gmail.isEmpty) {
            debugPrint('  ⚠️ Skipping user with empty Gmail');
            continue;
          }

          // Check if user exists in local DB
          final localUser = await DatabaseHelper.instance.getUserByGmail(gmail);

          final userModel = UserModel(
            name: mappedUser['Name']?.toString() ?? '',
            gmail: gmail,
            address: mappedUser['Address']?.toString() ?? '',
            villageCode: mappedUser['VillageCode']?.toString() ?? '',
            passwordHash: mappedUser['PasswordHash']?.toString() ?? '',
            lat: _parseDouble(mappedUser['Latitude']),
            lng: _parseDouble(mappedUser['Longitude']),
            status: mappedUser['Status']?.toString() ?? 'Pending',
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
      debugPrint('🔄 Syncing admins from Sheets...');

      // Fetch all admins from Sheets
      final sheetAdmins = await SheetsService.instance.fetchAllAdmins(
        _webAppUrl!,
      );

      debugPrint('📊 Fetched ${sheetAdmins.length} admins from Sheets');

      if (sheetAdmins.isEmpty) {
        debugPrint('ℹ️ No admins in Sheets');
        return _SyncCount(0);
      }

      int syncedCount = 0;

      for (final sheetAdmin in sheetAdmins) {
        try {
          final mappedAdmin = _mapSheetToLocal(sheetAdmin);
          final gmail = mappedAdmin['Gmail']?.toString();
          if (gmail == null || gmail.isEmpty) {
            debugPrint('  ⚠️ Skipping admin with empty Gmail');
            continue;
          }

          debugPrint('  🔍 Checking admin: $gmail');

          // Check if admin exists in local DB
          final localAdmin = await DatabaseHelper.instance.getAdminByGmail(
            gmail,
          );

          if (localAdmin == null) {
            // Insert new admin
            debugPrint('  📝 Inserting admin: $gmail');
            await DatabaseHelper.instance.insertAdmin(mappedAdmin);
            syncedCount++;
            debugPrint('  ➕ Added admin: $gmail');
          } else {
            debugPrint('  ✓ Admin already exists: $gmail');
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

  /// Sync equipment from Google Sheets to Local Database
  Future<_SyncCount> _syncEquipmentFromSheets() async {
    try {
      debugPrint('🔄 Syncing equipment from Sheets...');

      // Fetch all equipment from Sheets
      final sheetEquipment = await SheetsService.instance.fetchAllEquipment(
        _webAppUrl!,
      );

      debugPrint('📊 Fetched ${sheetEquipment.length} equipment from Sheets');

      if (sheetEquipment.isEmpty) {
        debugPrint('ℹ️ No equipment in Sheets, syncing local to Sheets...');
        // If Sheets is empty, sync local equipment to Sheets
        await _syncLocalEquipmentToSheets();
        return _SyncCount(0);
      }

      int syncedCount = 0;

      for (final sheetItem in sheetEquipment) {
        try {
          final mappedItem = _mapSheetToLocal(sheetItem);
          final id = mappedItem['ID'];
          if (id == null) {
            debugPrint('  ⚠️ Skipping equipment with empty ID');
            continue;
          }

          debugPrint('  🔍 Checking equipment: $id');

          // Check if equipment exists in local DB
          final localItem = await DatabaseHelper.instance.getEquipmentById(
            id is int ? id : int.tryParse(id.toString()) ?? 0,
          );

          final sheetUpdatedAt = mappedItem['UpdatedAt']?.toString() ?? '';
          final localUpdatedAt = localItem?['updated_at']?.toString() ?? '';

          if (localItem == null) {
            // Insert new equipment
            debugPrint('  📝 Inserting equipment: $id');
            await DatabaseHelper.instance.insertEquipment({
              'id': id,
              'name': mappedItem['Name']?.toString() ?? '',
              'description': mappedItem['Description']?.toString() ?? '',
              'category': mappedItem['Category']?.toString() ?? 'ทั่วไป',
              'quantity': mappedItem['Quantity'] ?? 1,
              'available': mappedItem['Available'] ?? 1,
              'status': mappedItem['Status']?.toString() ?? 'Available',
              'image_url': '',
              'created_at':
                  mappedItem['CreatedAt']?.toString() ??
                  DateTime.now().toIso8601String(),
              'updated_at': sheetUpdatedAt.isNotEmpty
                  ? sheetUpdatedAt
                  : DateTime.now().toIso8601String(),
              'synced': 1, // Mark as synced since it came from Sheets
            });
            syncedCount++;
            debugPrint('  ➕ Added equipment: $id');
          } else {
            // Check if local item is unsynced (has pending changes)
            final isUnsynced = localItem['synced'] == 0;

            if (isUnsynced) {
              // Local has pending changes, compare timestamps
              if (sheetUpdatedAt.isNotEmpty && localUpdatedAt.isNotEmpty) {
                final sheetTime = DateTime.parse(sheetUpdatedAt);
                final localTime = DateTime.parse(localUpdatedAt);

                if (sheetTime.isAfter(localTime)) {
                  // Sheet is newer, apply Sheet data (Sheet wins)
                  debugPrint(
                    '  ⚠️ Conflict: Sheet is newer, applying Sheet data',
                  );
                  await DatabaseHelper.instance.updateEquipment(
                    id is int ? id : int.tryParse(id.toString()) ?? 0,
                    {
                      'name': mappedItem['Name']?.toString() ?? '',
                      'description':
                          mappedItem['Description']?.toString() ?? '',
                      'category':
                          mappedItem['Category']?.toString() ?? 'ทั่วไป',
                      'quantity': mappedItem['Quantity'] ?? 1,
                      'available': mappedItem['Available'] ?? 1,
                      'status': mappedItem['Status']?.toString() ?? 'Available',
                      'updated_at': sheetUpdatedAt,
                    },
                  );
                  await DatabaseHelper.instance.markEquipmentAsSynced(
                    id is int ? id : int.tryParse(id.toString()) ?? 0,
                  );
                  syncedCount++;
                  debugPrint('  🔄 Conflict resolved: Sheet data applied');
                } else {
                  // Local is newer, keep local changes (will be synced later)
                  debugPrint('  ✓ Local changes are newer, keeping local data');
                }
              }
            } else {
              // No pending local changes, check if Sheet data changed
              final needsUpdate =
                  localItem['name'] != mappedItem['Name'] ||
                  localItem['available'] != mappedItem['Available'] ||
                  localItem['status'] != mappedItem['Status'] ||
                  localItem['description'] != mappedItem['Description'] ||
                  localItem['category'] != mappedItem['Category'] ||
                  localItem['quantity'] != mappedItem['Quantity'];

              if (needsUpdate) {
                await DatabaseHelper.instance.updateEquipment(
                  id is int ? id : int.tryParse(id.toString()) ?? 0,
                  {
                    'name': mappedItem['Name']?.toString() ?? '',
                    'description': mappedItem['Description']?.toString() ?? '',
                    'category': mappedItem['Category']?.toString() ?? 'ทั่วไป',
                    'quantity': mappedItem['Quantity'] ?? 1,
                    'available': mappedItem['Available'] ?? 1,
                    'status': mappedItem['Status']?.toString() ?? 'Available',
                    'updated_at': sheetUpdatedAt.isNotEmpty
                        ? sheetUpdatedAt
                        : DateTime.now().toIso8601String(),
                  },
                );
                await DatabaseHelper.instance.markEquipmentAsSynced(
                  id is int ? id : int.tryParse(id.toString()) ?? 0,
                );
                syncedCount++;
                debugPrint('  🔄 Updated equipment: $id');
              } else {
                debugPrint('  ✓ Equipment already up to date: $id');
              }
            }
          }
        } catch (e) {
          debugPrint('  ⚠️ Error syncing equipment: $e');
        }
      }

      debugPrint('✓ Equipment synced from Sheets: $syncedCount');
      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Error syncing equipment from Sheets: $e');
      return _SyncCount(0);
    }
  }

  /// Manual sync trigger (for pull-to-refresh)
  Future<SyncResult> manualSync(String webAppUrl) async {
    _webAppUrl = webAppUrl;
    return await syncAll();
  }

  /// Force reset sync lock (use only if sync is stuck)
  void resetSyncLock() {
    _isSyncing = false;
    debugPrint('🔓 Sync lock force reset');
  }

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

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

  /// Sync local equipment to Google Sheets
  Future<void> _syncLocalEquipmentToSheets() async {
    try {
      debugPrint('🔄 Syncing local equipment to Sheets...');

      final localEquipment = await DatabaseHelper.instance.getAllEquipment();

      if (localEquipment.isEmpty) {
        debugPrint('ℹ️ No local equipment to sync');
        return;
      }

      int syncedCount = 0;

      for (final item in localEquipment) {
        try {
          final success = await SheetsService.instance
              .addEquipment(_webAppUrl!, {
                'name': item['name'],
                'description': item['description'],
                'category': item['category'],
                'quantity': item['quantity'],
                'available': item['available'],
                'status': item['status'],
              });

          if (success) {
            syncedCount++;
            debugPrint('  ➕ Synced to Sheets: ${item['name']}');
          }
        } catch (e) {
          debugPrint('  ⚠️ Error syncing ${item['name']}: $e');
        }
      }

      debugPrint('✓ Local equipment synced to Sheets: $syncedCount');
    } catch (e) {
      debugPrint('❌ Error syncing local equipment to Sheets: $e');
    }
  }

  /// Sync unsynced equipment to Google Sheets (Continuous Sync)
  Future<_SyncCount> _syncUnsyncedEquipmentToSheets() async {
    try {
      debugPrint('🔄 Syncing unsynced equipment to Sheets...');

      final unsyncedEquipment = await DatabaseHelper.instance
          .getUnsyncedEquipment();

      if (unsyncedEquipment.isEmpty) {
        debugPrint('ℹ️ No unsynced equipment');
        return _SyncCount(0);
      }

      debugPrint('📊 Found ${unsyncedEquipment.length} unsynced equipment');

      int syncedCount = 0;

      for (final item in unsyncedEquipment) {
        try {
          final id = item['id'] as int;
          debugPrint('  🔄 Syncing equipment ID: $id (${item['name']})');

          // Update equipment in Sheets with conflict resolution
          final result = await SheetsService.instance
              .updateEquipment(_webAppUrl!, id, {
                'name': item['name'],
                'description': item['description'],
                'category': item['category'],
                'quantity': item['quantity'],
                'available': item['available'],
                'status': item['status'],
                'updated_at': item['updated_at'],
              });

          if (result['status'] == 'ok') {
            // Mark as synced in local DB
            await DatabaseHelper.instance.markEquipmentAsSynced(id);
            syncedCount++;
            debugPrint('  ✅ Synced: ${item['name']}');
          } else if (result['status'] == 'conflict') {
            // Conflict: Sheet data is newer
            debugPrint('  ⚠️ Conflict detected for ${item['name']}');
            debugPrint('  📥 Pulling newer data from Sheets...');

            // Fetch latest data from Sheets
            final sheetEquipment = await SheetsService.instance
                .fetchAllEquipment(_webAppUrl!);
            final sheetItem = sheetEquipment.firstWhere(
              (e) => e['ID'] == id,
              orElse: () => {},
            );

            if (sheetItem.isNotEmpty) {
              // Update local DB with Sheet data (Sheet wins)
              final mappedSheetItem = _mapSheetToLocal(sheetItem);
              await DatabaseHelper.instance.updateEquipment(id, {
                'name': mappedSheetItem['Name'],
                'description': mappedSheetItem['Description'],
                'category': mappedSheetItem['Category'],
                'quantity': mappedSheetItem['Quantity'],
                'available': mappedSheetItem['Available'],
                'status': mappedSheetItem['Status'],
                'updated_at':
                    mappedSheetItem['UpdatedAt'] ??
                    DateTime.now().toIso8601String(),
              });
              await DatabaseHelper.instance.markEquipmentAsSynced(id);
              debugPrint('  ✅ Resolved conflict: Sheet data applied to local');
            }
          } else if (result['status'] == 'not_found') {
            // Equipment not found in Sheets, add it
            debugPrint('  ➕ Equipment not found in Sheets, adding...');
            final success = await SheetsService.instance
                .addEquipment(_webAppUrl!, {
                  'name': item['name'],
                  'description': item['description'],
                  'category': item['category'],
                  'quantity': item['quantity'],
                  'available': item['available'],
                  'status': item['status'],
                });
            if (success) {
              await DatabaseHelper.instance.markEquipmentAsSynced(id);
              syncedCount++;
              debugPrint('  ✅ Added to Sheets: ${item['name']}');
            }
          }
        } catch (e) {
          debugPrint('  ⚠️ Error syncing ${item['name']}: $e');
        }
      }

      debugPrint('✓ Unsynced equipment synced to Sheets: $syncedCount');
      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Error syncing unsynced equipment to Sheets: $e');
      return _SyncCount(0);
    }
  }

  /// Sync transactions from Google Sheets to Local Database
  Future<_SyncCount> _syncTransactionsFromSheets() async {
    try {
      debugPrint('🔄 Syncing transactions from Sheets...');

      // Fetch all transactions from Sheets
      final sheetTransactions = await SheetsService.instance
          .fetchAllTransactions(_webAppUrl!);

      debugPrint(
        '📊 Fetched ${sheetTransactions.length} transactions from Sheets',
      );

      if (sheetTransactions.isEmpty) {
        debugPrint('ℹ️ No transactions in Sheets');
        return _SyncCount(0);
      }

      int syncedCount = 0;

      for (final sheetTx in sheetTransactions) {
        try {
          final mappedTx = _mapSheetToLocal(sheetTx);
          final id = mappedTx['ID'];
          if (id == null) {
            debugPrint('  ⚠️ Skipping transaction with empty ID');
            continue;
          }

          debugPrint('  🔍 Checking transaction: $id');

          // Check if transaction exists in local DB
          final localTx = await DatabaseHelper.instance.getTransactionById(
            id is int ? id : int.tryParse(id.toString()) ?? 0,
          );

          if (localTx == null) {
            // Insert new transaction
            debugPrint('  📝 Inserting transaction: $id');
            await DatabaseHelper.instance.insertTransaction({
              'id': id,
              'equipment_id': mappedTx['EquipmentID'] ?? 0,
              'user_gmail': mappedTx['UserGmail']?.toString() ?? '',
              'borrow_date': mappedTx['BorrowDate']?.toString() ?? '',
              'return_date': mappedTx['ReturnDate']?.toString() ?? '',
              'actual_return_date': mappedTx['ActualReturnDate']?.toString(),
              'status': mappedTx['Status']?.toString() ?? 'Borrowed',
              'notes': mappedTx['Notes']?.toString() ?? '',
              'created_at':
                  mappedTx['BorrowDate']?.toString() ??
                  DateTime.now().toIso8601String(),
            });
            syncedCount++;
            debugPrint('  ➕ Added transaction: $id');
          } else {
            // Check if transaction needs updating
            final needsUpdate =
                localTx['status'] != mappedTx['Status'] ||
                localTx['actual_return_date'] != mappedTx['ActualReturnDate'] ||
                localTx['notes'] != mappedTx['Notes'];

            if (needsUpdate) {
              await DatabaseHelper.instance.updateTransaction(
                id is int ? id : int.tryParse(id.toString()) ?? 0,
                {
                  'status': mappedTx['Status']?.toString() ?? 'Borrowed',
                  'actual_return_date': mappedTx['ActualReturnDate']
                      ?.toString(),
                  'notes': mappedTx['Notes']?.toString() ?? '',
                },
              );
              syncedCount++;
              debugPrint('  🔄 Updated transaction: $id');
            } else {
              debugPrint('  ✓ Transaction already up to date: $id');
            }
          }
        } catch (e) {
          debugPrint('  ⚠️ Error syncing transaction: $e');
        }
      }

      debugPrint('✓ Transactions synced from Sheets: $syncedCount');
      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Error syncing transactions from Sheets: $e');
      return _SyncCount(0);
    }
  }

  /// Sync transactions from Local DB to Google Sheets
  Future<_SyncCount> _syncTransactionsToSheets() async {
    try {
      debugPrint('🔄 Syncing unsynced transactions to Sheets...');

      final unsyncedTransactions = await DatabaseHelper.instance
          .getUnsyncedTransactions();
      debugPrint(
        '📊 Found ${unsyncedTransactions.length} unsynced transactions in Local DB',
      );

      if (unsyncedTransactions.isEmpty) {
        return _SyncCount(0);
      }

      int syncedCount = 0;

      for (final tx in unsyncedTransactions) {
        try {
          final result = await SheetsService.instance.addTransaction(
            _webAppUrl!,
            {
              'id': tx['id'].toString(),
              'equipment_id': tx['equipment_id'].toString(),
              'user_gmail': tx['user_gmail'].toString(),
              'borrow_date': tx['borrow_date'].toString(),
              'return_date': tx['return_date'].toString(),
              'actual_return_date': tx['actual_return_date']?.toString() ?? '',
              'status': tx['status'].toString(),
              'notes': tx['notes']?.toString() ?? '',
            },
          );

          if (result['status'] == 'ok') {
            // Mark as synced in local DB
            await DatabaseHelper.instance.markTransactionAsSynced(
              tx['id'] as int,
            );
            syncedCount++;
            debugPrint('  ✅ Synced transaction: ${tx['id']}');
          } else {
            debugPrint(
              '  ⚠️ Failed to sync transaction ${tx['id']}: ${result['message']}',
            );
          }
        } catch (e) {
          debugPrint('  ⚠️ Failed to sync transaction ${tx['id']}: $e');
        }
      }

      debugPrint('✅ Synced $syncedCount unsynced transactions to Sheets');
      return _SyncCount(syncedCount);
    } catch (e) {
      debugPrint('❌ Failed to sync transactions: $e');
      return _SyncCount(0);
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _isSyncing = false; // Reset sync flag on dispose
  }

  /// Force reset sync lock (use only if sync is stuck)
  void forceResetSyncLock() {
    _isSyncing = false;
    debugPrint('🔓 Sync lock force reset');
  }
}

/// Sync result model
class SyncResult {
  final bool success;
  final String message;
  final int usersSynced;
  final int adminsSynced;
  final int equipmentSynced;
  final int transactionsSynced;
  final int pendingSynced;

  SyncResult({
    required this.success,
    required this.message,
    this.usersSynced = 0,
    this.adminsSynced = 0,
    this.equipmentSynced = 0,
    this.transactionsSynced = 0,
    this.pendingSynced = 0,
  });

  int get totalSynced =>
      usersSynced +
      adminsSynced +
      equipmentSynced +
      transactionsSynced +
      pendingSynced;

  String get detailMessage {
    if (!success) return message;

    final parts = <String>[];
    if (usersSynced > 0) parts.add('Users: $usersSynced');
    if (adminsSynced > 0) parts.add('Admins: $adminsSynced');
    if (equipmentSynced > 0) parts.add('Equipment: $equipmentSynced');
    if (transactionsSynced > 0) parts.add('Transactions: $transactionsSynced');
    if (pendingSynced > 0) parts.add('Pending: $pendingSynced');

    if (parts.isEmpty) return 'ข้อมูลเป็นปัจจุบันแล้ว';
    return 'Synced: ${parts.join(', ')}';
  }
}

/// Internal sync count helper
class _SyncCount {
  final int count;
  _SyncCount(this.count);
}
