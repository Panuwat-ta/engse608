import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events_reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Add support for foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  color_hex $textType,
  icon_key $textType,
  created_at $textType,
  updated_at $textType
)
''');

    await db.execute('''
CREATE TABLE events (
  id $idType,
  title $textType,
  description TEXT,
  category_id $intType,
  event_date $textType,
  start_time $textType,
  end_time $textType,
  status $textType,
  priority $intType,
  created_at $textType,
  updated_at $textType,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
)
''');

    await db.execute('''
CREATE TABLE reminders (
  id $idType,
  event_id $intType,
  minutes_before $intType,
  remind_at $textType,
  is_enabled $intType,
  FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
