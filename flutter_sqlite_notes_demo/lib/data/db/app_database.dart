import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'notes_app.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ตัวอย่าง: ถ้าอนาคตมีการเพิ่มคอลัมน์ ให้จัดการที่นี่
        // if (oldVersion < 2) { await db.execute('ALTER TABLE notes ADD COLUMN ...'); }
      },
      onConfigure: (db) async {
        // เปิด foreign keys (เผื่อมีตารางอื่นในอนาคต)
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute(''' 
      CREATE TABLE notes ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        title TEXT NOT NULL, 
        content TEXT NOT NULL, 
        created_at TEXT NOT NULL, 
        updated_at TEXT NOT NULL 
      ); 
    ''');

    await db.execute('CREATE INDEX idx_notes_updated_at ON notes(updated_at);');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
