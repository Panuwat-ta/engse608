// lib/database/database_helper.dart
// SQLite singleton for local storage

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sync_queue_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'community_tool.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table: registered users (local cache)
    await db.execute('''
      CREATE TABLE registration_local (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        gmail         TEXT    NOT NULL UNIQUE,
        address       TEXT    NOT NULL,
        village_code  TEXT    NOT NULL DEFAULT '',
        password_hash TEXT    NOT NULL DEFAULT '',
        lat           REAL    NOT NULL,
        lng           REAL    NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'Pending'
      )
    ''');

    // Table: offline sync queue
    await db.execute('''
      CREATE TABLE sync_queue (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        payload    TEXT    NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Table: app configuration (Web App URL, Spreadsheet ID, etc.)
    await db.execute('''
      CREATE TABLE app_config (
        config_key   TEXT PRIMARY KEY,
        config_value TEXT NOT NULL
      )
    ''');

    // Table: admins (local cache)
    await db.execute('''
      CREATE TABLE admins_local (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        gmail         TEXT    NOT NULL UNIQUE,
        password_hash TEXT    NOT NULL,
        role          TEXT    NOT NULL DEFAULT 'Admin',
        village_code  TEXT    NOT NULL DEFAULT '',
        created_at    TEXT    NOT NULL
      )
    ''');

    // Table: equipment (local cache)
    await db.execute('''
      CREATE TABLE equipment_local (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        description TEXT    NOT NULL DEFAULT '',
        category    TEXT    NOT NULL DEFAULT 'ทั่วไป',
        quantity    INTEGER NOT NULL DEFAULT 1,
        available   INTEGER NOT NULL DEFAULT 1,
        status      TEXT    NOT NULL DEFAULT 'Available',
        image_url   TEXT    NOT NULL DEFAULT '',
        created_at  TEXT    NOT NULL,
        updated_at  TEXT    NOT NULL,
        synced      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Table: transactions (borrow/return records)
    await db.execute('''
      CREATE TABLE transactions_local (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        equipment_id      INTEGER NOT NULL,
        user_gmail        TEXT    NOT NULL,
        borrow_date       TEXT    NOT NULL,
        return_date       TEXT    NOT NULL,
        actual_return_date TEXT,
        status            TEXT    NOT NULL DEFAULT 'Borrowed',
        notes             TEXT    NOT NULL DEFAULT '',
        created_at        TEXT    NOT NULL,
        synced            INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (equipment_id) REFERENCES equipment_local (id)
      )
    ''');

    // Insert default equipment data
    await _insertDefaultEquipment(db);
  }

  Future<void> _insertDefaultEquipment(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultEquipment = [
      {
        'name': 'เครื่องตัดหญ้า',
        'description': 'เครื่องตัดหญ้าไฟฟ้า สภาพดี',
        'category': 'เครื่องมือสวน',
        'quantity': 2,
        'available': 2,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'บันไดอลูมิเนียม',
        'description': 'บันได 6 ขั้น น้ำหนักเบา',
        'category': 'เครื่องมือช่าง',
        'quantity': 3,
        'available': 3,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'เครื่องเจาะไฟฟ้า',
        'description': 'เครื่องเจาะไฟฟ้า พร้อมดอกเจาะ',
        'category': 'เครื่องมือช่าง',
        'quantity': 1,
        'available': 1,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'โต๊ะพับ',
        'description': 'โต๊ะพับสำหรับจัดงาน ขนาด 180x75 ซม.',
        'category': 'เฟอร์นิเจอร์',
        'quantity': 10,
        'available': 10,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'เก้าอี้พลาสติก',
        'description': 'เก้าอี้พลาสติกสำหรับจัดงาน',
        'category': 'เฟอร์นิเจอร์',
        'quantity': 50,
        'available': 50,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'เต็นท์',
        'description': 'เต็นท์ขนาด 3x3 เมตร',
        'category': 'อุปกรณ์กลางแจ้ง',
        'quantity': 5,
        'available': 5,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'เครื่องขยายเสียง',
        'description': 'เครื่องขยายเสียงพร้อมไมค์ 2 ตัว',
        'category': 'อิเล็กทรอนิกส์',
        'quantity': 1,
        'available': 1,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'พัดลมอุตสาหกรรม',
        'description': 'พัดลมอุตสาหกรรม 18 นิ้ว',
        'category': 'อิเล็กทรอนิกส์',
        'quantity': 4,
        'available': 4,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'เครื่องสูบน้ำ',
        'description': 'เครื่องสูบน้ำขนาดเล็ก',
        'category': 'เครื่องมือสวน',
        'quantity': 1,
        'available': 1,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
      {
        'name': 'รถเข็น',
        'description': 'รถเข็นสำหรับขนของ',
        'category': 'เครื่องมือทั่วไป',
        'quantity': 2,
        'available': 2,
        'status': 'Available',
        'image_url': '',
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      },
    ];

    for (final equipment in defaultEquipment) {
      await db.insert('equipment_local', equipment);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add app_config table for existing databases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_config (
          config_key   TEXT PRIMARY KEY,
          config_value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add admins_local table for existing databases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS admins_local (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          name          TEXT    NOT NULL,
          gmail         TEXT    NOT NULL UNIQUE,
          password_hash TEXT    NOT NULL,
          role          TEXT    NOT NULL DEFAULT 'Admin',
          village_code  TEXT    NOT NULL DEFAULT '',
          created_at    TEXT    NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add equipment_local table for existing databases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS equipment_local (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          name        TEXT    NOT NULL,
          description TEXT    NOT NULL DEFAULT '',
          category    TEXT    NOT NULL DEFAULT 'ทั่วไป',
          quantity    INTEGER NOT NULL DEFAULT 1,
          available   INTEGER NOT NULL DEFAULT 1,
          status      TEXT    NOT NULL DEFAULT 'Available',
          image_url   TEXT    NOT NULL DEFAULT '',
          created_at  TEXT    NOT NULL,
          updated_at  TEXT    NOT NULL,
          synced      INTEGER NOT NULL DEFAULT 0
        )
      ''');
      // Insert default equipment data
      await _insertDefaultEquipment(db);
    }
    if (oldVersion < 5) {
      // Add updated_at and synced columns to existing equipment_local table
      try {
        await db.execute(
          'ALTER TABLE equipment_local ADD COLUMN updated_at TEXT NOT NULL DEFAULT ""',
        );
        await db.execute(
          'ALTER TABLE equipment_local ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
        );
        // Update existing rows with current timestamp
        final now = DateTime.now().toIso8601String();
        await db.execute(
          'UPDATE equipment_local SET updated_at = ?, synced = 0 WHERE updated_at = ""',
          [now],
        );
      } catch (e) {
        debugPrint('Columns may already exist: $e');
      }
    }
    if (oldVersion < 6) {
      // Add transactions_local table for existing databases
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions_local (
          id                INTEGER PRIMARY KEY AUTOINCREMENT,
          equipment_id      INTEGER NOT NULL,
          user_gmail        TEXT    NOT NULL,
          borrow_date       TEXT    NOT NULL,
          return_date       TEXT    NOT NULL,
          actual_return_date TEXT,
          status            TEXT    NOT NULL DEFAULT 'Borrowed',
          notes             TEXT    NOT NULL DEFAULT '',
          created_at        TEXT    NOT NULL,
          FOREIGN KEY (equipment_id) REFERENCES equipment_local (id)
        )
      ''');
    }
    if (oldVersion < 7) {
      // Add synced column to transactions_local table
      try {
        await db.execute(
          'ALTER TABLE transactions_local ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        debugPrint('Synced column may already exist in transactions: $e');
      }
    }
  }

  // ─── registration_local CRUD ──────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(
      'registration_local',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('registration_local');
    return maps.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> getUserByGmail(String gmail) async {
    final db = await database;
    final maps = await db.query(
      'registration_local',
      where: 'gmail = ?',
      whereArgs: [gmail],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUserStatus(String gmail, String status) async {
    final db = await database;
    return await db.update(
      'registration_local',
      {'status': status},
      where: 'gmail = ?',
      whereArgs: [gmail],
    );
  }

  Future<int> deleteUser(String gmail) async {
    final db = await database;
    return await db.delete(
      'registration_local',
      where: 'gmail = ?',
      whereArgs: [gmail],
    );
  }

  // ─── sync_queue CRUD ──────────────────────────────────────────────────────

  Future<int> insertSyncItem(SyncQueueItem item) async {
    final db = await database;
    return await db.insert('sync_queue', item.toMap());
  }

  Future<List<SyncQueueItem>> getAllSyncItems() async {
    final db = await database;
    final maps = await db.query('sync_queue', orderBy: 'created_at ASC');
    return maps.map(SyncQueueItem.fromMap).toList();
  }

  Future<int> deleteSyncItem(int id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  // ─── app_config CRUD ──────────────────────────────────────────────────────

  /// Save or update a config value
  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert('app_config', {
      'config_key': key,
      'config_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get a config value by key
  Future<String?> getConfig(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_config',
      where: 'config_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['config_value'] as String?;
  }

  /// Get all config entries
  Future<Map<String, String>> getAllConfig() async {
    final db = await database;
    final maps = await db.query('app_config');
    final result = <String, String>{};
    for (final map in maps) {
      result[map['config_key'] as String] = map['config_value'] as String;
    }
    return result;
  }

  /// Delete a config entry
  Future<int> deleteConfig(String key) async {
    final db = await database;
    return await db.delete(
      'app_config',
      where: 'config_key = ?',
      whereArgs: [key],
    );
  }

  /// Clear all config entries
  Future<void> clearAllConfig() async {
    final db = await database;
    await db.delete('app_config');
  }

  // ─── admins_local CRUD ────────────────────────────────────────────────────

  /// Insert or update admin
  Future<int> insertAdmin(Map<String, dynamic> admin) async {
    final db = await database;
    return await db.insert('admins_local', {
      'name': admin['Name'] ?? '',
      'gmail': admin['Gmail'] ?? '',
      'password_hash': admin['PasswordHash'] ?? '',
      'role': admin['Role'] ?? 'Admin',
      'village_code': admin['VillageCode'] ?? '',
      'created_at': admin['CreatedAt'] ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all admins
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    final db = await database;
    final maps = await db.query('admins_local');
    return maps
        .map(
          (m) => {
            'Name': m['name'],
            'Gmail': m['gmail'],
            'PasswordHash': m['password_hash'],
            'Role': m['role'],
            'VillageCode': m['village_code'],
            'CreatedAt': m['created_at'],
          },
        )
        .toList();
  }

  /// Get admin by gmail
  Future<Map<String, dynamic>?> getAdminByGmail(String gmail) async {
    final db = await database;
    final maps = await db.query(
      'admins_local',
      where: 'gmail = ?',
      whereArgs: [gmail],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    return {
      'Name': m['name'],
      'Gmail': m['gmail'],
      'PasswordHash': m['password_hash'],
      'Role': m['role'],
      'VillageCode': m['village_code'],
      'CreatedAt': m['created_at'],
    };
  }

  /// Delete admin
  Future<int> deleteAdmin(String gmail) async {
    final db = await database;
    return await db.delete(
      'admins_local',
      where: 'gmail = ?',
      whereArgs: [gmail],
    );
  }

  /// Clear all admins
  Future<void> clearAllAdmins() async {
    final db = await database;
    await db.delete('admins_local');
  }

  // ─── equipment_local CRUD ─────────────────────────────────────────────────

  /// Get all equipment
  Future<List<Map<String, dynamic>>> getAllEquipment() async {
    final db = await database;
    return await db.query('equipment_local', orderBy: 'name ASC');
  }

  /// Get equipment by ID
  Future<Map<String, dynamic>?> getEquipmentById(int id) async {
    final db = await database;
    final maps = await db.query(
      'equipment_local',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get equipment by category
  Future<List<Map<String, dynamic>>> getEquipmentByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      'equipment_local',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
  }

  /// Get available equipment only
  Future<List<Map<String, dynamic>>> getAvailableEquipment() async {
    final db = await database;
    return await db.query(
      'equipment_local',
      where: 'available > 0 AND status = ?',
      whereArgs: ['Available'],
      orderBy: 'name ASC',
    );
  }

  /// Insert equipment
  Future<int> insertEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    // Set updated_at and synced=0 for new equipment
    equipment['updated_at'] = DateTime.now().toIso8601String();
    equipment['synced'] = 0;
    return await db.insert('equipment_local', equipment);
  }

  /// Update equipment
  Future<int> updateEquipment(int id, Map<String, dynamic> equipment) async {
    final db = await database;
    // Set updated_at and synced=0 when updating
    equipment['updated_at'] = DateTime.now().toIso8601String();
    equipment['synced'] = 0;
    return await db.update(
      'equipment_local',
      equipment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update equipment availability
  Future<int> updateEquipmentAvailability(int id, int available) async {
    final db = await database;
    return await db.update(
      'equipment_local',
      {
        'available': available,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark equipment as synced
  Future<int> markEquipmentAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'equipment_local',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced equipment
  Future<List<Map<String, dynamic>>> getUnsyncedEquipment() async {
    final db = await database;
    return await db.query(
      'equipment_local',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'updated_at ASC',
    );
  }

  /// Delete equipment
  Future<int> deleteEquipment(int id) async {
    final db = await database;
    return await db.delete('equipment_local', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all equipment
  Future<void> clearAllEquipment() async {
    final db = await database;
    await db.delete('equipment_local');
  }

  /// Get equipment categories
  Future<List<String>> getEquipmentCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM equipment_local ORDER BY category ASC',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  // ─── transactions_local CRUD ──────────────────────────────────────────────

  /// Insert transaction
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    // Set synced=0 for new transactions (needs to be synced to Sheets)
    transaction['synced'] = transaction['synced'] ?? 0;
    return await db.insert('transactions_local', transaction);
  }

  /// Get all transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        e.name as equipment_name,
        e.category as equipment_category
      FROM transactions_local t
      LEFT JOIN equipment_local e ON t.equipment_id = e.id
      ORDER BY t.created_at DESC
    ''');
  }

  /// Get transactions by user
  Future<List<Map<String, dynamic>>> getTransactionsByUser(
    String userGmail,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        t.*,
        e.name as equipment_name,
        e.category as equipment_category
      FROM transactions_local t
      LEFT JOIN equipment_local e ON t.equipment_id = e.id
      WHERE t.user_gmail = ?
      ORDER BY t.created_at DESC
    ''',
      [userGmail],
    );
  }

  /// Get transactions by status
  Future<List<Map<String, dynamic>>> getTransactionsByStatus(
    String status,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        t.*,
        e.name as equipment_name,
        e.category as equipment_category
      FROM transactions_local t
      LEFT JOIN equipment_local e ON t.equipment_id = e.id
      WHERE t.status = ?
      ORDER BY t.created_at DESC
    ''',
      [status],
    );
  }

  /// Get transaction by ID
  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        t.*,
        e.name as equipment_name,
        e.category as equipment_category
      FROM transactions_local t
      LEFT JOIN equipment_local e ON t.equipment_id = e.id
      WHERE t.id = ?
    ''',
      [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update transaction
  Future<int> updateTransaction(
    int id,
    Map<String, dynamic> transaction,
  ) async {
    final db = await database;
    // Set synced=0 when updating (needs to be synced to Sheets)
    transaction['synced'] = transaction['synced'] ?? 0;
    return await db.update(
      'transactions_local',
      transaction,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Return equipment (update transaction status to "Returned" - pending admin approval)
  /// Equipment availability is NOT increased until admin approves
  Future<bool> returnEquipment(int transactionId) async {
    final db = await database;

    try {
      // Get transaction details
      final transaction = await getTransactionById(transactionId);
      if (transaction == null) return false;

      final now = DateTime.now().toIso8601String();

      // Update transaction status to "Returned" (pending admin approval)
      // Do NOT increase equipment availability yet
      await db.update(
        'transactions_local',
        {'status': 'Returned', 'actual_return_date': now, 'synced': 0},
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      return true;
    } catch (e) {
      debugPrint('Error returning equipment: $e');
      return false;
    }
  }

  /// Complete return (admin approved) - increase equipment availability
  Future<bool> completeReturn(int transactionId) async {
    final db = await database;

    try {
      // Get transaction details
      final transaction = await getTransactionById(transactionId);
      if (transaction == null) return false;

      final equipmentId = transaction['equipment_id'] as int;
      final now = DateTime.now().toIso8601String();

      // Update transaction status to "Completed"
      await db.update(
        'transactions_local',
        {'status': 'Completed', 'synced': 0},
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // Increase equipment availability
      await db.rawUpdate(
        '''
        UPDATE equipment_local 
        SET available = available + 1,
            updated_at = ?,
            synced = 0
        WHERE id = ?
      ''',
        [now, equipmentId],
      );

      return true;
    } catch (e) {
      debugPrint('Error completing return: $e');
      return false;
    }
  }

  /// Borrow equipment (create transaction and decrease availability)
  Future<int?> borrowEquipment({
    required int equipmentId,
    required String userGmail,
    required String returnDate,
    String notes = '',
  }) async {
    final db = await database;

    try {
      // Check if equipment is available
      final equipment = await getEquipmentById(equipmentId);
      if (equipment == null) return null;

      final available = equipment['available'] as int;
      if (available <= 0) return null;

      final now = DateTime.now().toIso8601String();

      // Create transaction
      final transactionId = await db.insert('transactions_local', {
        'equipment_id': equipmentId,
        'user_gmail': userGmail,
        'borrow_date': now,
        'return_date': returnDate,
        'status': 'Borrowed',
        'notes': notes,
        'created_at': now,
        'synced': 0, // Mark as unsynced
      });

      // Decrease equipment availability
      await db.rawUpdate(
        '''
        UPDATE equipment_local 
        SET available = available - 1,
            updated_at = ?,
            synced = 0
        WHERE id = ?
      ''',
        [now, equipmentId],
      );

      return transactionId;
    } catch (e) {
      debugPrint('Error borrowing equipment: $e');
      return null;
    }
  }

  /// Get active (borrowed) transactions count for user
  Future<int> getActiveBorrowCount(String userGmail) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM transactions_local
      WHERE user_gmail = ? AND status = 'Borrowed'
    ''',
      [userGmail],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total borrow count for user
  Future<int> getTotalBorrowCount(String userGmail) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM transactions_local
      WHERE user_gmail = ?
    ''',
      [userGmail],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions_local',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all transactions
  Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete('transactions_local');
  }

  /// Add synced column to transactions table for future use
  Future<void> addSyncedColumnToTransactions() async {
    final db = await database;
    try {
      await db.execute(
        'ALTER TABLE transactions_local ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
      );
    } catch (e) {
      // Column may already exist
      debugPrint('Synced column may already exist in transactions: $e');
    }
  }

  /// Mark transaction as synced
  Future<int> markTransactionAsSynced(int id) async {
    final db = await database;
    return await db.update(
      'transactions_local',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced transactions
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        e.name as equipment_name,
        e.category as equipment_category
      FROM transactions_local t
      LEFT JOIN equipment_local e ON t.equipment_id = e.id
      WHERE t.synced = 0
      ORDER BY t.created_at ASC
    ''');
  }
}
