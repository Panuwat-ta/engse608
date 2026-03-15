// lib/screens/pending_returns_screen.dart
// Admin screen to approve equipment returns

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';

class PendingReturnsScreen extends StatefulWidget {
  const PendingReturnsScreen({super.key});

  @override
  State<PendingReturnsScreen> createState() => _PendingReturnsScreenState();
}

class _PendingReturnsScreenState extends State<PendingReturnsScreen> {
  List<Map<String, dynamic>> _pendingReturns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingReturns();
  }

  Future<void> _loadPendingReturns() async {
    setState(() => _loading = true);

    try {
      // Get all transactions with status "Returned" (pending admin approval)
      final allTransactions = await DatabaseHelper.instance
          .getAllTransactions();

      final pending = allTransactions
          .where((tx) => tx['status'] == 'Returned')
          .toList();

      // Enrich with equipment and user info
      for (var tx in pending) {
        final equipmentId = tx['equipment_id'] as int;
        final equipment = await DatabaseHelper.instance.getEquipmentById(
          equipmentId,
        );
        if (equipment != null) {
          tx['equipment_name'] = equipment['name'];
        }

        final userGmail = tx['user_gmail'] as String;
        final user = await DatabaseHelper.instance.getUserByGmail(userGmail);
        if (user != null) {
          tx['user_name'] = user.name;
        }
      }

      setState(() {
        _pendingReturns = pending;
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

  Future<void> _approveReturn(Map<String, dynamic> transaction) async {
    final appProvider = context.read<AppProvider>();

    try {
      // Record return to Google Sheets
      final result = await SheetsService.instance.recordReturn(
        appProvider.webAppUrl,
        transactionId: transaction['id'] as int,
        equipmentId: transaction['equipment_id'] as int,
        equipmentName: transaction['equipment_name'] ?? '',
        userGmail: transaction['user_gmail'] ?? '',
        userName: transaction['user_name'] ?? '',
        borrowDate: transaction['borrow_date'] ?? '',
        returnDate: transaction['return_date'] ?? '',
        actualReturnDate:
            transaction['actual_return_date'] ??
            DateTime.now().toIso8601String(),
        approvedBy: appProvider.adminEmail,
        notes: transaction['notes'] ?? '',
      );

      if (result['status'] == 'ok') {
        // Complete the return in local database (increase equipment availability)
        final completed = await DatabaseHelper.instance.completeReturn(
          transaction['id'] as int,
        );

        if (completed) {
          // Remove from pending list
          setState(() {
            _pendingReturns.removeWhere((tx) => tx['id'] == transaction['id']);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ อนุมัติการคืนสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ ไม่สามารถอัปเดตฐานข้อมูลได้'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        title: const Text('รอการยืนยันการคืน'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadPendingReturns,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingReturns.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีรายการรอการยืนยัน',
                    style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingReturns.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = _pendingReturns[index];
                final borrowDate = DateTime.parse(tx['borrow_date']);
                final returnDate = DateTime.parse(tx['return_date']);
                final actualReturnDate = tx['actual_return_date'] != null
                    ? DateTime.parse(tx['actual_return_date'])
                    : DateTime.now();
                final isOverdue = actualReturnDate.isAfter(returnDate);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isOverdue
                          ? Colors.red.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
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
                                color: isOverdue
                                    ? Colors.red.withAlpha(25)
                                    : Colors.orange.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.assignment_return_rounded,
                                color: isOverdue ? Colors.red : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['equipment_name'] ?? 'อุปกรณ์',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    tx['user_name'] ?? tx['user_gmail'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'เกินกำหนด',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ยืม: ${borrowDate.day}/${borrowDate.month}/${borrowDate.year + 543}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.event_rounded,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'คืน: ${actualReturnDate.day}/${actualReturnDate.month}/${actualReturnDate.year + 543}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (tx['notes'] != null &&
                            tx['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'หมายเหตุ: ${tx['notes']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _approveReturn(tx),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('อนุมัติการคืน'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
