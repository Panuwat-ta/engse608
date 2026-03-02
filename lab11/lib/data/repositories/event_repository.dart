import 'package:lab11/data/db/database_helper.dart';
import 'package:lab11/data/models/event.dart';

class EventRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertEvent(Event event) async {
    final db = await _dbHelper.database;
    return await db.insert('events', event.toMap());
  }

  Future<List<Event>> getEvents({
    String? dateFilter, // "today", "week", "month"
    int? categoryId,
    String? status,
    String? searchQuery,
    String sortBy = 'event_date ASC, start_time ASC',
  }) async {
    final db = await _dbHelper.database;

    String whereStr = '1=1';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereStr += ' AND title LIKE ?';
      whereArgs.add('%$searchQuery%');
    }

    if (categoryId != null) {
      whereStr += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (status != null && status.isNotEmpty) {
      whereStr += ' AND status = ?';
      whereArgs.add(status);
    }

    if (dateFilter != null) {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      if (dateFilter == 'today') {
        whereStr += ' AND event_date = ?';
        whereArgs.add(todayStr);
      } else if (dateFilter == 'week') {
        // Simple 7-day lookahead
        final nextWeek = now.add(const Duration(days: 7));
        final nextWeekStr =
            "${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}";
        whereStr += ' AND event_date >= ? AND event_date <= ?';
        whereArgs.addAll([todayStr, nextWeekStr]);
      } else if (dateFilter == 'month') {
        final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
        whereStr += ' AND event_date LIKE ?';
        whereArgs.add('$monthStr%');
      }
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: whereStr,
      whereArgs: whereArgs,
      orderBy: sortBy,
    );

    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  Future<Event?> getEventById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateEvent(Event event) async {
    final db = await _dbHelper.database;
    final map = event.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'events',
      map,
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEventStatus(int id, String newStatus) async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> values = {
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return await db.update('events', values, where: 'id = ?', whereArgs: [id]);
  }
}
