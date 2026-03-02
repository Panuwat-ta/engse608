import 'package:flutter/material.dart';
import 'package:lab11/data/models/event.dart';
import 'package:lab11/data/models/category.dart';
import 'package:lab11/ui/widgets/category_badge.dart';
import 'package:lab11/ui/widgets/status_chip.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Category? category;
  final VoidCallback onTap;

  const EventCard({
    Key? key,
    required this.event,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(status: event.status),
                ],
              ),
              const SizedBox(height: 8),
              if (category != null) ...[
                CategoryBadge(
                  name: category!.name,
                  colorHex: category!.colorHex,
                  iconKey: category!.iconKey,
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.eventDate,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${event.startTime} - ${event.endTime}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              if (event.priority > 1) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: event.priority == 3 ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.priority == 3 ? 'High Priority' : 'Normal Priority',
                      style: TextStyle(
                        color: event.priority == 3 ? Colors.red : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
