import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  int get itemCount => _items.length;

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString('cart_items');

      if (cartJson != null && cartJson.isNotEmpty) {
        // We need all products to reconstruct CartItems
        // For now, we'll load an empty cart and let the UI handle it
        _items = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartJson = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('cart_items', cartJson);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingItemIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingItemIndex >= 0) {
      // Item already exists, update quantity
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + quantity,
      );
    } else {
      // Add new item
      _items.add(CartItem(product: product, quantity: quantity));
    }
    
    saveCart();
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    saveCart();
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final itemIndex = _items.indexWhere((item) => item.product.id == productId);
    if (itemIndex >= 0) {
      _items[itemIndex] = _items[itemIndex].copyWith(quantity: newQuantity);
      saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    saveCart();
    notifyListeners();
  }

  bool isInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(int productId) {
    if (_items.isEmpty) return 0;
    final item = _items.firstWhere((item) => item.product.id == productId, orElse: () => CartItem(product: _items.first.product, quantity: 0));
    return item.quantity;
  }
}