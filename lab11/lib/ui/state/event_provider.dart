import 'package:flutter/foundation.dart';
import 'package:lab11/data/models/event.dart';
import 'package:lab11/data/models/reminder.dart';
import 'package:lab11/data/repositories/event_repository.dart';
import 'package:lab11/data/repositories/reminder_repository.dart';
import 'package:lab11/services/notification_service.dart';
import 'package:intl/intl.dart';

class EventProvider with ChangeNotifier {
  final EventRepository _eventRepository = EventRepository();
  final ReminderRepository _reminderRepository = ReminderRepository();
  final NotificationService _notificationService = NotificationService();

  List<Event> _events = [];
  bool _isLoading = false;

  // Filters
  String? _dateFilter; // "today", "week", "month", null (all)
  int? _categoryIdFilter;
  String? _statusFilter;
  String? _searchQuery;
  String _sortBy = 'event_date ASC, start_time ASC';

  List<Event> get events => _events;
  bool get isLoading => _isLoading;

  String? get dateFilter => _dateFilter;
  int? get categoryIdFilter => _categoryIdFilter;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  EventProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    _events = await _eventRepository.getEvents(
      dateFilter: _dateFilter,
      categoryId: _categoryIdFilter,
      status: _statusFilter,
      searchQuery: _searchQuery,
      sortBy: _sortBy,
    );

    _isLoading = false;
    notifyListeners();
  }

  void setFilters({
    String? dateFilter,
    int? categoryIdFilter,
    String? statusFilter,
    String? searchQuery,
    String? sortBy,
  }) {
    if (dateFilter != null) _dateFilter = dateFilter;
    if (categoryIdFilter != null) _categoryIdFilter = categoryIdFilter;
    if (statusFilter != null) _statusFilter = statusFilter;
    if (searchQuery != null) _searchQuery = searchQuery;
    if (sortBy != null) _sortBy = sortBy;

    // Clear filters if empty string provided
    if (_dateFilter == '') _dateFilter = null;
    if (_categoryIdFilter == -1) _categoryIdFilter = null;
    if (_statusFilter == '') _statusFilter = null;
    if (_searchQuery == '') _searchQuery = null;

    loadEvents();
  }

  void clearFilters() {
    _dateFilter = null;
    _categoryIdFilter = null;
    _statusFilter = null;
    _searchQuery = null;
    _sortBy = 'event_date ASC, start_time ASC';
    loadEvents();
  }

  Future<void> addEvent(Event event, List<Reminder> reminders) async {
    final eventId = await _eventRepository.insertEvent(event);

    for (var reminder in reminders) {
      final newReminder = reminder.copyWith(eventId: eventId);
      final reminderId = await _reminderRepository.insertReminder(newReminder);

      // Schedule notification
      if (newReminder.isEnabled == 1) {
        await _scheduleNotification(
          event.copyWith(id: eventId),
          newReminder.copyWith(id: reminderId),
        );
      }
    }

    await loadEvents();
  }

  Future<void> updateEvent(Event event, List<Reminder> reminders) async {
    await _eventRepository.updateEvent(event);

    // Simplest way is to remove old reminders, cancel notifications, and add new ones
    final oldReminders = await _reminderRepository.getRemindersByEventId(
      event.id!,
    );
    for (var r in oldReminders) {
      if (r.id != null) {
        await _notificationService.cancelNotification(r.id!);
      }
    }
    await _reminderRepository.deleteRemindersByEventId(event.id!);

    for (var reminder in reminders) {
      final newReminder = reminder.copyWith(eventId: event.id);
      final reminderId = await _reminderRepository.insertReminder(newReminder);

      // Reschedule updated notifications
      if (newReminder.isEnabled == 1 &&
          event.status != 'completed' &&
          event.status != 'cancelled') {
        await _scheduleNotification(
          event,
          newReminder.copyWith(id: reminderId),
        );
      }
    }

    await loadEvents();
  }

  Future<void> deleteEvent(int eventId) async {
    final oldReminders = await _reminderRepository.getRemindersByEventId(
      eventId,
    );
    for (var r in oldReminders) {
      if (r.id != null) {
        await _notificationService.cancelNotification(r.id!);
      }
    }
    await _eventRepository.deleteEvent(eventId);
    await loadEvents();
  }

  Future<void> changeEventStatus(int eventId, String newStatus) async {
    await _eventRepository.updateEventStatus(eventId, newStatus);

    if (newStatus == 'completed' || newStatus == 'cancelled') {
      // Cancel active notifications
      final reminders = await _reminderRepository.getRemindersByEventId(
        eventId,
      );
      for (var r in reminders) {
        if (r.id != null) {
          await _notificationService.cancelNotification(r.id!);
        }
      }
      await _reminderRepository.disableRemindersByEventId(eventId);
    }

    await loadEvents();
  }

  Future<void> _scheduleNotification(Event event, Reminder reminder) async {
    if (reminder.id == null) return;

    try {
      // Parses "YYYY-MM-DD" and "HH:mm"
      final eventDateTimeStr = "${event.eventDate} ${event.startTime}";
      final format = DateFormat("yyyy-MM-dd HH:mm");
      final eventDateTime = format.parse(eventDateTimeStr);

      final notifyTime = eventDateTime.subtract(
        Duration(minutes: reminder.minutesBefore),
      );

      await _notificationService.scheduleNotification(
        id: reminder.id!,
        title: "Reminder: ${event.title}",
        body: "Starts in ${reminder.minutesBefore} minutes",
        scheduledDate: notifyTime,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  Future<List<Reminder>> getRemindersForEvent(int eventId) async {
    return await _reminderRepository.getRemindersByEventId(eventId);
  }
}
