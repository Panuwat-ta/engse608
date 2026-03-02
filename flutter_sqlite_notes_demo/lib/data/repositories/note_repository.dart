import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/note.dart';

class NoteRepository {
  static const table = 'notes';

  Future<int> insertNote(Note note) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      table,
      note.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getAllNotes() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(table, orderBy: 'updated_at DESC');
    return rows.map((e) => Note.fromMap(e)).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<int> updateNote(Note note) async {
    if (note.id == null) {
      throw ArgumentError('Note id is required for update');
    }
    final db = await AppDatabase.instance.database;
    return db.update(
      table,
      note.toMap()..remove('created_at'), // ไม่แก้ created_at
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    final db = await AppDatabase.instance.database;
    return db.delete(table);
  }
}
