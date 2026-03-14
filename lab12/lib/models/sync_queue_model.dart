// lib/models/sync_queue_model.dart
// Model for offline sync queue — stores payloads that failed to send

class SyncQueueItem {
  final int? id;
  final String payload; // JSON string of the POST body
  final int createdAt; // Unix timestamp in milliseconds

  const SyncQueueItem({
    this.id,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'payload': payload,
      'created_at': createdAt,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      payload: map['payload'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  @override
  String toString() => 'SyncQueueItem(id: $id, createdAt: $createdAt)';
}
