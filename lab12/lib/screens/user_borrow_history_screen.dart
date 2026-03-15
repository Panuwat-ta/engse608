// lib/screens/user_borrow_history_screen.dart
// Screen showing user's borrow history

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';

class UserBorrowHistoryScreen extends StatefulWidget {
  const UserBorrowHistoryScreen({super.key});

  @override
  State<UserBorrowHistoryScreen> createState() =>
      _UserBorrowHistoryScreenState();
}

class _UserBorrowHistoryScreenState extends State<UserBorrowHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String _filter =
      'All'; // 'All', 'Borrowed', 'Returned', 'Completed', 'Overdue'

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);

    try {
      final currentUser = context.read<AppProvider>().currentUser;
      if (currentUser == null) {
        setState(() => _loading = false);
        return;
      }

      final transactions = await DatabaseHelper.instance.getTransactionsByUser(
        currentUser.gmail,
      );

      // Check for overdue transactions
      final now = DateTime.now();
      for (var tx in transactions) {
        if (tx['status'] == 'Borrowed') {
          final returnDate = DateTime.parse(tx['return_date']);
          if (now.isAfter(returnDate)) {
            tx['status'] = 'Overdue';
          }
        }
      }

      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    List<Map<String, dynamic>> filtered;
    if (_filter == 'All') {
      filtered = _transactions;
    } else {
      filtered = _transactions.where((t) => t['status'] == _filter).toList();
    }

    // Group by equipment_id and status
    final Map<String, Map<String, dynamic>> grouped = {};

    for (var tx in filtered) {
      final key = '${tx['equipment_id']}_${tx['status']}';

      if (grouped.containsKey(key)) {
        // Increment count
        grouped[key]!['count'] = (grouped[key]!['count'] as int) + 1;
        // Keep the most recent transaction dates
        final existingBorrow = DateTime.parse(grouped[key]!['borrow_date']);
        final currentBorrow = DateTime.parse(tx['borrow_date']);
        if (currentBorrow.isAfter(existingBorrow)) {
          grouped[key]!['borrow_date'] = tx['borrow_date'];
          grouped[key]!['return_date'] = tx['return_date'];
          grouped[key]!['id'] = tx['id']; // Use most recent transaction ID
        }
      } else {
        // First occurrence
        grouped[key] = Map<String, dynamic>.from(tx);
        grouped[key]!['count'] = 1;
        grouped[key]!['transaction_ids'] = [tx['id']];
      }
    }

    return grouped.values.toList();
  }

  Future<void> _showReturnQuantityDialog(
    int transactionId,
    int equipmentId,
    String equipmentName,
    int maxCount,
  ) async {
    int selectedQuantity = maxCount;
    final TextEditingController quantityController = TextEditingController(
      text: maxCount.toString(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('เลือกจำนวนที่จะคืน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                equipmentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedQuantity > 1
                        ? () {
                            setState(() {
                              selectedQuantity--;
                              quantityController.text = selectedQuantity
                                  .toString();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Show text field dialog to edit quantity
                      final result = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          final editController = TextEditingController(
                            text: selectedQuantity.toString(),
                          );
                          return AlertDialog(
                            title: const Text('ระบุจำนวน'),
                            content: TextField(
                              controller: editController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: 'จำนวน (1-$maxCount)',
                                border: const OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {
                                final qty = int.tryParse(value);
                                if (qty != null &&
                                    qty >= 1 &&
                                    qty <= maxCount) {
                                  Navigator.pop(context, qty);
                                }
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('ยกเลิก'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  final qty = int.tryParse(editController.text);
                                  if (qty != null &&
                                      qty >= 1 &&
                                      qty <= maxCount) {
                                    Navigator.pop(context, qty);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'กรุณาระบุจำนวน 1-$maxCount',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('ตกลง'),
                              ),
                            ],
                          );
                        },
                      );

                      if (result != null) {
                        setState(() {
                          selectedQuantity = result;
                          quantityController.text = result.toString();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$selectedQuantity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: selectedQuantity < maxCount
                        ? () {
                            setState(() {
                              selectedQuantity++;
                              quantityController.text = selectedQuantity
                                  .toString();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'คืนได้สูงสุด $maxCount ชิ้น (แตะที่ตัวเลขเพื่อแก้ไข)',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยันการคืน'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _returnEquipment(
        transactionId,
        equipmentId,
        equipmentName,
        selectedQuantity,
      );
    }
  }

  Future<void> _returnEquipment(
    int transactionId,
    int equipmentId,
    String equipmentName,
    int quantity,
  ) async {
    try {
      // Get transaction details before updating
      final allTransactions = await DatabaseHelper.instance
          .getAllTransactions();
      final transaction = allTransactions.firstWhere(
        (tx) => tx['id'] == transactionId,
        orElse: () => <String, dynamic>{},
      );

      if (transaction.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ ไม่พบข้อมูลการยืม'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update local database status to "Returned"
      final success = await DatabaseHelper.instance.returnEquipment(
        transactionId,
      );

      if (!mounted) return;

      if (success) {
        // Get current user info
        final currentUser = context.read<AppProvider>().currentUser;
        final appProvider = context.read<AppProvider>();

        // Record to Returns sheet immediately with status "รอการอนุมัติ"
        if (appProvider.webAppUrl.isNotEmpty) {
          final result = await SheetsService.instance.recordReturn(
            appProvider.webAppUrl,
            transactionId: transactionId,
            equipmentId: equipmentId,
            equipmentName: equipmentName,
            userGmail: currentUser?.gmail ?? '',
            userName: currentUser?.name ?? '',
            borrowDate: transaction['borrow_date'] ?? '',
            returnDate: transaction['return_date'] ?? '',
            actualReturnDate: DateTime.now().toIso8601String(),
            approvedBy: 'รอการอนุมัติ', // Status: pending approval
            notes:
                'คืน $quantity ชิ้น${transaction['notes']?.toString().isNotEmpty == true ? ' - ${transaction['notes']}' : ''}',
          );

          if (result['status'] != 'ok') {
            debugPrint(
              '⚠️ Failed to record return to sheet: ${result['message']}',
            );
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ส่งคำขอคืนอุปกรณ์ $quantity ชิ้นแล้ว รอ Admin อนุมัติ',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadTransactions();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ไม่สามารถคืนได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการยืม'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (!_loading && _transactions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ทั้งหมด',
                    selected: _filter == 'All',
                    onTap: () => setState(() => _filter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'กำลังยืม',
                    selected: _filter == 'Borrowed',
                    onTap: () => setState(() => _filter = 'Borrowed'),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'รอการอนุมัติ',
                    selected: _filter == 'Returned',
                    onTap: () => setState(() => _filter = 'Returned'),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'คืนแล้ว',
                    selected: _filter == 'Completed',
                    onTap: () => setState(() => _filter = 'Completed'),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'เกินกำหนด',
                    selected: _filter == 'Overdue',
                    onTap: () => setState(() => _filter = 'Overdue'),
                    color: Colors.red,
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'All'
                              ? 'ยังไม่มีประวัติการยืม'
                              : 'ไม่มีรายการ',
                          style: TextStyle(
                            fontSize: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (ctx, i) {
                        final tx = _filteredTransactions[i];
                        final count = tx['count'] as int? ?? 1;
                        return _TransactionCard(
                          transaction: tx,
                          onReturn: count > 1
                              ? () => _showReturnQuantityDialog(
                                  tx['id'] as int,
                                  tx['equipment_id'] as int,
                                  tx['equipment_name']?.toString() ?? '',
                                  count,
                                )
                              : () => _returnEquipment(
                                  tx['id'] as int,
                                  tx['equipment_id'] as int,
                                  tx['equipment_name']?.toString() ?? '',
                                  1,
                                ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onReturn;

  const _TransactionCard({required this.transaction, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = transaction['status']?.toString() ?? 'Unknown';
    final equipmentName = transaction['equipment_name']?.toString() ?? '-';
    final borrowDate = DateTime.parse(transaction['borrow_date']);
    final returnDate = DateTime.parse(transaction['return_date']);
    final notes = transaction['notes']?.toString() ?? '';
    final count = transaction['count'] as int? ?? 1;

    final statusColor = _getStatusColor(status);
    final canReturn = status == 'Borrowed' || status == 'Overdue';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getStatusIcon(status), color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              equipmentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (count > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'x$count',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'ยืม: ${borrowDate.day}/${borrowDate.month}/${borrowDate.year + 543}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Icon(Icons.event_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'คืน: ${returnDate.day}/${returnDate.month}/${returnDate.year + 543}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'หมายเหตุ: $notes',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
            if (canReturn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.assignment_return_rounded),
                  label: Text(
                    count > 1 ? 'คืนอุปกรณ์ ($count ชิ้น)' : 'คืนอุปกรณ์',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Borrowed':
        return Colors.blue;
      case 'Returned':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Borrowed':
        return Icons.schedule_rounded;
      case 'Returned':
        return Icons.hourglass_top_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Overdue':
        return Icons.warning_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Borrowed':
        return 'กำลังยืม';
      case 'Returned':
        return 'รอการอนุมัติ';
      case 'Completed':
        return 'คืนแล้ว';
      case 'Overdue':
        return 'เกินกำหนด';
      default:
        return status;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : chipColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
