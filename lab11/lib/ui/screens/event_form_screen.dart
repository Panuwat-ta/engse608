import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lab11/data/models/event.dart';
import 'package:lab11/data/models/reminder.dart';
import 'package:lab11/ui/state/category_provider.dart';
import 'package:lab11/ui/state/event_provider.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({Key? key, this.event}) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;

  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: TimeOfDay.now().hour + 1 > 23 ? 23 : TimeOfDay.now().hour + 1,
  );
  String _selectedStatus = 'pending';
  int _priority = 1;

  // Reminders
  bool _enableReminder = false;
  int _reminderMinutesBefore = 30;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(
      text: widget.event?.description ?? '',
    );

    if (widget.event != null) {
      _selectedCategoryId = widget.event!.categoryId;
      _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.event!.eventDate);
      _startTime = TimeOfDay(
        hour: int.parse(widget.event!.startTime.split(':')[0]),
        minute: int.parse(widget.event!.startTime.split(':')[1]),
      );
      _endTime = TimeOfDay(
        hour: int.parse(widget.event!.endTime.split(':')[0]),
        minute: int.parse(widget.event!.endTime.split(':')[1]),
      );
      _selectedStatus = widget.event!.status;
      _priority = widget.event!.priority;

      _loadReminders();
    }
  }

  Future<void> _loadReminders() async {
    if (widget.event != null && widget.event!.id != null) {
      final reminders = await context
          .read<EventProvider>()
          .getRemindersForEvent(widget.event!.id!);
      if (reminders.isNotEmpty) {
        final r = reminders.first;
        setState(() {
          _enableReminder = r.isEnabled == 1;
          _reminderMinutesBefore = r.minutesBefore;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  bool _isEndTimeValid() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes > startMinutes;
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (!_isEndTimeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time!')),
      );
      return;
    }

    final String dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final String startStr =
        "${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}";
    final String endStr =
        "${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}";

    final newEvent = Event(
      id: widget.event?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      categoryId: _selectedCategoryId!,
      eventDate: dateStr,
      startTime: startStr,
      endTime: endStr,
      status: _selectedStatus,
      priority: _priority,
    );

    List<Reminder> reminders = [];
    if (_enableReminder) {
      // Build a full DateTime from date + time, then subtract reminder minutes
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final notifyTime = eventDateTime.subtract(
        Duration(minutes: _reminderMinutesBefore),
      );

      reminders.add(
        Reminder(
          eventId: widget.event?.id ?? 0,
          minutesBefore: _reminderMinutesBefore,
          remindAt: notifyTime.toIso8601String(),
          isEnabled: 1,
        ),
      );
    }

    final provider = context.read<EventProvider>();
    if (widget.event == null) {
      await provider.addEvent(newEvent, reminders);
    } else {
      await provider.updateEvent(newEvent, reminders);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveEvent),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, catProvider, child) {
          if (catProvider.categories.isEmpty && !catProvider.isLoading) {
            return const Center(child: Text('Create a category first!'));
          }

          if (_selectedCategoryId == null &&
              catProvider.categories.isNotEmpty &&
              widget.event == null) {
            _selectedCategoryId = catProvider.categories.first.id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategoryId,
                    items: catProvider.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_startTime.format(context)),
                                const Icon(Icons.access_time, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_endTime.format(context)),
                                const Icon(Icons.access_time, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isEndTimeValid())
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'End time must be after start time',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    value: _priority,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Low')),
                      DropdownMenuItem(value: 2, child: Text('Normal')),
                      DropdownMenuItem(value: 3, child: Text('High')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _priority = val!;
                      });
                    },
                  ),

                  const Divider(height: 32),
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Reminder'),
                    value: _enableReminder,
                    onChanged: (val) => setState(() => _enableReminder = val),
                  ),
                  if (_enableReminder)
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Remind me before',
                        border: OutlineInputBorder(),
                      ),
                      value: _reminderMinutesBefore,
                      items: [5, 10, 15, 30, 60, 120].map((mins) {
                        return DropdownMenuItem(
                          value: mins,
                          child: Text('$mins minutes'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _reminderMinutesBefore = val!;
                        });
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
