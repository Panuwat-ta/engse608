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
      final appProvider = context.read<AppProvider>();

      if (appProvider.webAppUrl.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Fetch returns from Google Sheets
      final returns = await SheetsService.instance.fetchAllReturns(
        appProvider.webAppUrl,
      );

      // Filter only pending returns and map Thai headers to English
      final pending = returns
          .where((ret) => ret['อนุมัติโดย'] == 'รอการอนุมัติ')
          .map(
            (ret) => {
              'ID': ret['ไอดี'],
              'TransactionID': ret['ไอดีรายการยืม'],
              'EquipmentID': ret['ไอดีอุปกรณ์'],
              'EquipmentName': ret['ชื่ออุปกรณ์'],
              'UserGmail': ret['อีเมลผู้ใช้'],
              'UserName': ret['ชื่อผู้ใช้'],
              'BorrowDate': ret['วันที่ยืม'],
              'ReturnDate': ret['วันที่ต้องคืน'],
              'ActualReturnDate': ret['วันที่คืนจริง'],
              'Overdue': ret['เกินกำหนด'],
              'Notes': ret['หมายเหตุ'],
              'ApprovedBy': ret['อนุมัติโดย'],
              'ApprovedAt': ret['วันที่อนุมัติ'],
              'RecordedAt': ret['วันที่บันทึก'],
              // Keep original Thai keys for backward compatibility
              ...ret,
            },
          )
          .toList();

      // Convert to mutable maps
      final enrichedPending = pending
          .map((ret) => Map<String, dynamic>.from(ret))
          .toList();

      setState(() {
        _pendingReturns = enrichedPending;
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
      // Update approval status in Google Sheets
      final success = await SheetsService.instance.updateReturnApproval(
        appProvider.webAppUrl,
        transaction['ไอดี'].toString(),
        appProvider.adminEmail,
      );

      if (success) {
        // Complete the return in local database (increase equipment availability)
        final transactionId = int.tryParse(
          transaction['ไอดีรายการยืม'].toString(),
        );
        if (transactionId != null) {
          await DatabaseHelper.instance.completeReturn(transactionId);
        }

        // Remove from pending list
        setState(() {
          _pendingReturns.removeWhere(
            (tx) => tx['ไอดี'] == transaction['ไอดี'],
          );
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
              content: Text('❌ ไม่สามารถอนุมัติได้'),
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
                final borrowDate = DateTime.parse(
                  tx['วันที่ยืม'] ?? DateTime.now().toIso8601String(),
                );
                final actualReturnDate = tx['วันที่คืนจริง'] != null
                    ? DateTime.parse(tx['วันที่คืนจริง'])
                    : DateTime.now();
                final isOverdue = tx['เกินกำหนด'] == 'Yes';

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
                                    tx['ชื่ออุปกรณ์'] ?? 'อุปกรณ์',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    tx['ชื่อผู้ใช้'] ?? tx['อีเมลผู้ใช้'] ?? '',
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
                        if (tx['หมายเหตุ'] != null &&
                            tx['หมายเหตุ'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'หมายเหตุ: ${tx['หมายเหตุ']}',
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
