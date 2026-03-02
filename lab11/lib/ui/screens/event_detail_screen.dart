import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lab11/data/models/event.dart';
import 'package:lab11/data/models/category.dart';
import 'package:lab11/data/models/reminder.dart';
import 'package:lab11/ui/state/category_provider.dart';
import 'package:lab11/ui/state/event_provider.dart';
import 'package:lab11/ui/widgets/category_badge.dart';
import 'package:lab11/ui/widgets/status_chip.dart';
import 'package:lab11/ui/screens/event_form_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<EventProvider>().deleteEvent(event.id!);
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close screen
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changeStatus(BuildContext context, String newStatus) async {
    await context.read<EventProvider>().changeEventStatus(event.id!, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status changed to $newStatus')));
      Navigator.pop(context); // go back to list to see update
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine category
    final categories = context.read<CategoryProvider>().categories;
    final Category? category = categories.cast<dynamic>().firstWhere(
      (c) => c.id == event.categoryId,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EventFormScreen(event: event),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip(status: event.status),
              ],
            ),
            const SizedBox(height: 16),
            if (category != null) ...[
              CategoryBadge(
                name: category.name,
                colorHex: category.colorHex,
                iconKey: category.iconKey,
              ),
              const SizedBox(height: 16),
            ],

            _buildDetailRow(Icons.calendar_today, 'Date', event.eventDate),
            _buildDetailRow(
              Icons.access_time,
              'Time',
              "${event.startTime} - ${event.endTime}",
            ),
            _buildDetailRow(
              Icons.flag,
              'Priority',
              event.priority == 1
                  ? 'Low'
                  : (event.priority == 2 ? 'Normal' : 'High'),
            ),

            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.description.isNotEmpty
                  ? event.description
                  : 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),
            const Text(
              'Reminders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Reminder>>(
              future: context.read<EventProvider>().getRemindersForEvent(
                event.id!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty ||
                    snapshot.data!.first.isEnabled == 0) {
                  return const Text('No active reminders for this event.');
                }

                final r = snapshot.data!.first;
                return ListTile(
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Colors.blue,
                  ),
                  title: Text('${r.minutesBefore} minutes before'),
                  subtitle: Text(
                    "Scheduled for: ${r.remindAt.substring(0, 16).replaceFirst('T', ' ')}",
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Status Action Buttons
            const Text(
              'Change Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                if (event.status != 'pending')
                  _statusButton(
                    context,
                    'pending',
                    'Mark Pending',
                    Colors.orange,
                  ),
                if (event.status != 'in_progress')
                  _statusButton(
                    context,
                    'in_progress',
                    'Start Progress',
                    Colors.blue,
                  ),
                if (event.status != 'completed')
                  _statusButton(
                    context,
                    'completed',
                    'Mark Completed',
                    Colors.green,
                  ),
                if (event.status != 'cancelled')
                  _statusButton(
                    context,
                    'cancelled',
                    'Cancel Event',
                    Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    String statusKey,
    String label,
    Color color,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _changeStatus(context, statusKey),
      child: Text(label),
    );
  }
}
