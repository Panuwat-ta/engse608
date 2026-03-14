// lib/database/database_helper.dart
// SQLite singleton for local storage

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      version: 3,
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
}
