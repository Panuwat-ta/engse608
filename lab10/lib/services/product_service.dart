import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  final String baseUrl = 'https://fakestoreapi.com';

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      print('API Response Status: ${response.statusCode}'); // Debug

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('API Data Length: ${data.length}'); // Debug
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}'); // Debug
        // Return fallback products if API fails
        print('Using fallback products'); // Debug
        return _getFallbackProducts();
      }
    } catch (e) {
      print('Network Error: $e'); // Debug
      print('Using fallback products'); // Debug
      return _getFallbackProducts();
    }
  }

  List<Product> _getFallbackProducts() {
    return [
      Product(
        id: 1,
        title: 'Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops',
        price: 109.95,
        description: 'Your perfect pack for everyday use and walks in the forest. Stash your laptop (up to 15 inches) in the padded sleeve, your everyday',
        category: 'men\'s clothing',
        image: 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
        rating: Rating(rate: 3.9, count: 120),
      ),
      Product(
        id: 2,
        title: 'Mens Casual Premium Slim Fit T-Shirts',
        price: 22.3,
        description: 'Slim-fitting style, contrast raglan long sleeve, three-button henley placket, light weight & soft fabric for breathable comfort',
        category: 'men\'s clothing',
        image: 'https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX346_.jpg',
        rating: Rating(rate: 4.3, count: 259),
      ),
      Product(
        id: 3,
        title: 'Mens Cotton Jacket',
        price: 55.99,
        description: 'great outerwear jackets for Spring/Autumn/Winter, suitable for many occasions, such as working, hiking, camping, mountain/rock climbing, cycling',
        category: 'men\'s clothing',
        image: 'https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg',
        rating: Rating(rate: 4.7, count: 500),
      ),
      Product(
        id: 4,
        title: 'SanDisk SSD PLUS 1TB Internal SSD - SATA III 6 Gb/s',
        price: 109.99,
        description: 'Easy upgrade for faster boot up, shutdown, application load and response (As compared to 5400 RPM SATA 2.5" hard drive; based on PCMark Vantage, Suite',
        category: 'electronics',
        image: 'https://fakestoreapi.com/img/61U7T1koQqL._AC_SX679_.jpg',
        rating: Rating(rate: 4.6, count: 340),
      ),
      Product(
        id: 5,
        title: 'Acer SB220Q bi 21.5 inches Full HD (1920 x 1080) IPS Ultra-Thin Monitor',
        price: 599.99,
        description: '21. 5 inches Full HD (1920 x 1080) widescreen IPS display And brilliant color (16. 7 million colors) 60Hz refresh rate',
        category: 'electronics',
        image: 'https://fakestoreapi.com/img/81QpkI9-5AL._AC_SX679_.jpg',
        rating: Rating(rate: 2.9, count: 250),
      ),
    ];
  }
}
