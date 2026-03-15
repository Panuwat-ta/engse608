// lib/screens/manage_admins_screen.dart
// Screen for managing admin users from Admins sheet

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final appProvider = context.read<AppProvider>();
    if (appProvider.webAppUrl.isEmpty) {
      setState(() {
        _error = 'ยังไม่ได้ตั้งค่า Web App URL';
        _loading = false;
      });
      return;
    }

    try {
      // Load from Local Database first (instant display)
      final admins = await DatabaseHelper.instance.getAllAdmins();

      setState(() {
        _admins = admins;
        _loading = false;
      });

      // Sync in background (don't wait)
      SyncService.instance.manualSync(appProvider.webAppUrl).then((result) {
        if (mounted && result.success) {
          // Reload data after sync completes
          _reloadFromDatabase();
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });
    }
  }

  Future<void> _reloadFromDatabase() async {
    try {
      final admins = await DatabaseHelper.instance.getAllAdmins();
      if (mounted) {
        setState(() {
          _admins = admins;
        });
      }
    } catch (e) {
      debugPrint('Error reloading admins from database: $e');
    }
  }

  Future<void> _deleteAdmin(String gmail, String name) async {
    final appProvider = context.read<AppProvider>();

    // Prevent deleting current admin
    if (gmail.toLowerCase() == appProvider.adminEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ ไม่สามารถลบ Admin ที่กำลังใช้งานได้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบ Admin "$name" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Sheets
      final success = await SheetsService.instance.deleteAdmin(
        appProvider.webAppUrl,
        gmail,
      );

      if (!mounted) return;

      if (success) {
        // Delete from Local Database
        await DatabaseHelper.instance.deleteAdmin(gmail);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ลบ Admin "$name" สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAdmins(); // Reload list
        }
      } else {
        throw Exception('Failed to delete admin');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ไม่สามารถลบได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentAdminEmail = context.read<AppProvider>().adminEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ดูแล (Admin)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAdmins,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: cs.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadAdmins,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Header card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 32,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผู้ดูแลระบบทั้งหมด',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              'จำนวน: ${_admins.length} คน',
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onPrimaryContainer.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Admin list
                Expanded(
                  child: _admins.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 64,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'ไม่มีข้อมูล Admin',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAdmins,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _admins.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final admin = _admins[i];
                              final name = admin['Name']?.toString() ?? '-';
                              final gmail = admin['Gmail']?.toString() ?? '-';
                              final role = admin['Role']?.toString() ?? 'Admin';
                              final villageCode =
                                  admin['VillageCode']?.toString() ?? '';
                              final createdAt =
                                  admin['CreatedAt']?.toString() ?? '';
                              final isCurrentAdmin =
                                  gmail.toLowerCase() ==
                                  currentAdminEmail.toLowerCase();

                              return Card(
                                elevation: isCurrentAdmin ? 2 : 0,
                                color: isCurrentAdmin
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: isCurrentAdmin
                                      ? BorderSide(color: cs.primary, width: 2)
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: isCurrentAdmin
                                                ? cs.primary
                                                : Colors.blue.shade100,
                                            child: Text(
                                              name
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isCurrentAdmin
                                                    ? Colors.white
                                                    : Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isCurrentAdmin)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: cs.primary,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'คุณ',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  gmail,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: cs.onSurfaceVariant,
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
                                          Icon(
                                            Icons.shield_rounded,
                                            size: 16,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'สิทธิ์: $role',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          if (villageCode.isNotEmpty) ...[
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.home_work_rounded,
                                              size: 16,
                                              color: cs.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'รหัส: $villageCode',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              createdAt.isNotEmpty
                                                  ? 'สร้างเมื่อ: ${_formatThaiDateTime(createdAt)}'
                                                  : 'ไม่ระบุวันที่',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isCurrentAdmin) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _deleteAdmin(gmail, name),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('ลบ Admin'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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

  String _formatThaiDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final thaiDateTime = dateTime.add(
        const Duration(hours: 7),
      ); // Convert to GMT+7

      const thaiMonths = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];

      final day = thaiDateTime.day;
      final month = thaiMonths[thaiDateTime.month - 1];
      final year = thaiDateTime.year + 543; // Convert to Buddhist year
      final hour = thaiDateTime.hour.toString().padLeft(2, '0');
      final minute = thaiDateTime.minute.toString().padLeft(2, '0');

      return '$day $month $year เวลา $hour:$minute น.';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
