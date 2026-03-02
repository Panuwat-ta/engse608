class Event {
  final int? id;
  final String title;
  final String description;
  final int categoryId;
  final String eventDate;
  final String startTime;
  final String endTime;
  final String status;
  final int priority;
  final String? createdAt;
  final String? updatedAt;

  Event({
    this.id,
    required this.title,
    this.description = '',
    required this.categoryId,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.status, // pending, in_progress, completed, cancelled
    required this.priority, // 1-3
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'category_id': categoryId,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'priority': priority,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      categoryId: map['category_id'] as int,
      eventDate: map['event_date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      status: map['status'] as String,
      priority: map['priority'] as int,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Event copyWith({
    int? id,
    String? title,
    String? description,
    int? categoryId,
    String? eventDate,
    String? startTime,
    String? endTime,
    String? status,
    int? priority,
    String? createdAt,
    String? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
