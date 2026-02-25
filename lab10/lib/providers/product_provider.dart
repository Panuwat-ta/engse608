import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name'; // name, price, rating
  bool _isAscending = true;

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get isAscending => _isAscending;

  List<String> get categories {
    final uniqueCategories = _products.map((p) => p.category).toSet().toList();
    final cats = ['All', ...uniqueCategories];
    print('Available categories: $cats'); // Debug
    return cats;
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getAllProducts();
      print('Loaded ${_products.length} products'); // Debug print
      _applyFiltersAndSort();
    } catch (e) {
      _error = e.toString();
      print('Error loading products: $e'); // Debug print
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _isAscending = !_isAscending;
    } else {
      _sortBy = sortBy;
      _isAscending = true;
    }
    _applyFiltersAndSort();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _sortBy = 'name';
    _isAscending = true;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredProducts = List.from(_products);
    print('Before filtering: ${_filteredProducts.length} products'); // Debug

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts.where((product) =>
          product.title.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery)
      ).toList();
      print('After search filter: ${_filteredProducts.length} products'); // Debug
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      final beforeFilter = _filteredProducts.length;
      _filteredProducts = _filteredProducts.where((product) =>
          product.category.toLowerCase().trim() == _selectedCategory.toLowerCase().trim()
      ).toList();
      print('Category filter: $_selectedCategory, $beforeFilter -> ${_filteredProducts.length}'); // Debug
    }

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        _filteredProducts.sort((a, b) => _isAscending 
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case 'price':
        _filteredProducts.sort((a, b) => _isAscending 
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'rating':
        _filteredProducts.sort((a, b) {
          final aRating = a.rating?.rate ?? 0;
          final bRating = b.rating?.rate ?? 0;
          return _isAscending 
              ? aRating.compareTo(bRating)
              : bRating.compareTo(aRating);
        });
        break;
    }

    print('Final filtered products: ${_filteredProducts.length}'); // Debug
    notifyListeners();
  }
}
