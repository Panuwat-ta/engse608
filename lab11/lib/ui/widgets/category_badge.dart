import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  final String name;
  final String colorHex;
  final String iconKey;

  const CategoryBadge({
    Key? key,
    required this.name,
    required this.colorHex,
    required this.iconKey,
  }) : super(key: key);

  Color _getColorFromHex(String hexColor) {
    if (hexColor.isEmpty) return Colors.grey;
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }

    // Fallback if parsing fails to avoid FormatException
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getIconData(String key) {
    // Simple mapping for demo
    switch (key) {
      case 'work':
        return Icons.work;
      case 'person':
        return Icons.person;
      case 'groups':
        return Icons.groups;
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'book':
        return Icons.book;
      case 'computer':
        return Icons.computer;
      case 'attach_money':
        return Icons.attach_money;
      case 'flight':
        return Icons.flight;
      default:
        return Icons.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(colorHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconData(iconKey), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
