// lib/models/transaction_model.dart
// Model for borrow/return transactions

class TransactionModel {
  final int? id;
  final int equipmentId;
  final String userGmail;
  final String borrowDate;
  final String returnDate;
  final String? actualReturnDate;
  final String status; // 'Borrowed', 'Returned', 'Overdue'
  final String notes;

  TransactionModel({
    this.id,
    required this.equipmentId,
    required this.userGmail,
    required this.borrowDate,
    required this.returnDate,
    this.actualReturnDate,
    this.status = 'Borrowed',
    this.notes = '',
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'user_gmail': userGmail,
      'borrow_date': borrowDate,
      'return_date': returnDate,
      'actual_return_date': actualReturnDate,
      'status': status,
      'notes': notes,
    };
  }

  // Create from Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      equipmentId: map['equipment_id'] as int,
      userGmail: map['user_gmail'] as String,
      borrowDate: map['borrow_date'] as String,
      returnDate: map['return_date'] as String,
      actualReturnDate: map['actual_return_date'] as String?,
      status: map['status'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }

  // Convert to Sheet row
  List<dynamic> toSheetRow() {
    return [
      id ?? '',
      equipmentId,
      userGmail,
      borrowDate,
      returnDate,
      actualReturnDate ?? '',
      status,
      notes,
    ];
  }

  // Headers for Google Sheets
  static List<String> get headers => [
    'ID',
    'EquipmentID',
    'UserGmail',
    'BorrowDate',
    'ReturnDate',
    'ActualReturnDate',
    'Status',
    'Notes',
  ];

  TransactionModel copyWith({
    int? id,
    int? equipmentId,
    String? userGmail,
    String? borrowDate,
    String? returnDate,
    String? actualReturnDate,
    String? status,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      userGmail: userGmail ?? this.userGmail,
      borrowDate: borrowDate ?? this.borrowDate,
      returnDate: returnDate ?? this.returnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  // Check if overdue
  bool get isOverdue {
    if (status == 'Returned') return false;
    final returnDateTime = DateTime.parse(returnDate);
    return DateTime.now().isAfter(returnDateTime);
  }
}
