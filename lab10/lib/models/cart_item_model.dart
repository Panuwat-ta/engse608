import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json, List<Product> allProducts) {
    final productId = json['productId'] as int?;
    final product = allProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => allProducts.first, // Fallback if product not found
    );
    return CartItem(
      product: product,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
