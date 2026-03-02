import 'package:flutter/foundation.dart' hide Category;
import 'package:lab11/data/models/category.dart';
import 'package:lab11/data/repositories/category_repository.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _repository.getCategories();

    // Add default categories if empty
    if (_categories.isEmpty) {
      await _addDefaultCategories();
      _categories = await _repository.getCategories();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _addDefaultCategories() async {
    await _repository.insertCategory(
      Category(name: 'Work', colorHex: '#FF5722', iconKey: 'work'),
    );
    await _repository.insertCategory(
      Category(name: 'Personal', colorHex: '#4CAF50', iconKey: 'person'),
    );
    await _repository.insertCategory(
      Category(name: 'Meeting', colorHex: '#2196F3', iconKey: 'groups'),
    );
  }

  Future<void> addCategory(Category category) async {
    await _repository.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    try {
      final hasEvents = await _repository.hasEvents(id);
      if (hasEvents) {
        throw Exception('Cannot delete category with associated events');
      }
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}
