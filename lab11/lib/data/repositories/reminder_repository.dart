import 'package:lab11/data/db/database_helper.dart';
import 'package:lab11/data/models/reminder.dart';

class ReminderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getRemindersByEventId(int eventId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return List.generate(maps.length, (i) {
      return Reminder.fromMap(maps[i]);
    });
  }

  Future<List<Reminder>> getActiveReminders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'is_enabled = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Reminder.fromMap(maps[i]);
    });
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRemindersByEventId(int eventId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'reminders',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Future<int> disableRemindersByEventId(int eventId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'reminders',
      {'is_enabled': 0},
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }
}
