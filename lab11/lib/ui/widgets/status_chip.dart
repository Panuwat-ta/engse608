import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange;
        label = 'Pending';
        break;
      case 'in_progress':
        bgColor = Colors.blue;
        label = 'In Progress';
        break;
      case 'completed':
        bgColor = Colors.green;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
