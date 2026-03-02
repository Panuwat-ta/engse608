import 'package:lab11/data/db/database_helper.dart';
import 'package:lab11/data/models/category.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    final map = category.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'categories',
      map,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    // Note: Due to FOREIGN KEY ... ON DELETE RESTRICT on events(category_id),
    // this will throw an exception if events are attached to this category.
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasEvents(int categoryId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'events',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
