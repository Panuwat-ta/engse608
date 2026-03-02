class Reminder {
  final int? id;
  final int eventId;
  final int minutesBefore;
  final String remindAt;
  final int isEnabled; // 0 or 1

  Reminder({
    this.id,
    required this.eventId,
    required this.minutesBefore,
    required this.remindAt,
    this.isEnabled = 1,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'event_id': eventId,
      'minutes_before': minutesBefore,
      'remind_at': remindAt,
      'is_enabled': isEnabled,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      minutesBefore: map['minutes_before'] as int,
      remindAt: map['remind_at'] as String,
      isEnabled: map['is_enabled'] as int? ?? 1,
    );
  }

  Reminder copyWith({
    int? id,
    int? eventId,
    int? minutesBefore,
    String? remindAt,
    int? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      remindAt: remindAt ?? this.remindAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
