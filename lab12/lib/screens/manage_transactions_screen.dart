// lib/screens/manage_transactions_screen.dart
// Screen for managing borrow/return transactions

import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ManageTransactionsScreen extends StatefulWidget {
  const ManageTransactionsScreen({super.key});

  @override
  State<ManageTransactionsScreen> createState() =>
      _ManageTransactionsScreenState();
}

class _ManageTransactionsScreenState extends State<ManageTransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = false;
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
      final transactions = await DatabaseHelper.instance.getAllTransactions();

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
    if (_filter == 'All') return _transactions;
    return _transactions.where((t) => t['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานะการยืม'),
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
                : _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ยังไม่มีรายการยืม-คืน',
                          style: TextStyle(
                            fontSize: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (ctx, i) {
                      final tx = _filteredTransactions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                              tx['status'] ?? '',
                            ).withAlpha(51),
                            child: Icon(
                              _getStatusIcon(tx['status'] ?? ''),
                              color: _getStatusColor(tx['status'] ?? ''),
                            ),
                          ),
                          title: Text(tx['equipment_name'] ?? ''),
                          subtitle: Text(tx['user_gmail'] ?? ''),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                tx['status'] ?? '',
                              ).withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tx['status'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(tx['status'] ?? ''),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
          color: selected ? chipColor : chipColor.withAlpha(51),
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
