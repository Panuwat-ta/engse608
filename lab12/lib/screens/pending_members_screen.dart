// lib/screens/pending_members_screen.dart
// Admin view: list of Pending members with Approve button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';

class PendingMembersScreen extends StatefulWidget {
  const PendingMembersScreen({super.key});

  @override
  State<PendingMembersScreen> createState() => _PendingMembersScreenState();
}

class _PendingMembersScreenState extends State<PendingMembersScreen> {
  List<Map<String, dynamic>> _allMembers = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final appProvider = context.read<AppProvider>();
    if (appProvider.webAppUrl.isEmpty) {
      setState(() {
        _error = 'ยังไม่ได้ตั้งค่า Web App URL\nกรุณาไปที่ตั้งค่า Google Sheet';
        _loading = false;
      });
      return;
    }

    try {
      // Load from Local Database first (instant display)
      final users = await DatabaseHelper.instance.getAllUsers();

      // Filter only pending members
      final pendingUsers = users
          .where((user) => user.status == 'Pending')
          .toList();

      // Convert UserModel to Map format for compatibility
      final members = pendingUsers
          .map(
            (user) => {
              'Name': user.name,
              'Gmail': user.gmail,
              'Address': user.address,
              'VillageCode': user.villageCode,
              'PasswordHash': user.passwordHash,
              'Latitude': user.lat,
              'Longitude': user.lng,
              'Status': user.status,
            },
          )
          .toList();

      setState(() {
        _allMembers = members;
        _loading = false;
        if (members.isEmpty) {
          _error =
              'ไม่มีสมาชิกรอการอนุมัติ 🎉\n\n'
              'หน้านี้แสดงรายชื่อสมาชิกที่รอการอนุมัติ\n'
              '(สถานะ Pending)';
        }
      });

      // Sync in background (don't wait)
      SyncService.instance.manualSync(appProvider.webAppUrl).then((result) {
        if (mounted && result.success && result.usersSynced > 0) {
          // Reload data after sync completes
          _reloadFromDatabase();
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'เกิดข้อผิดพลาดในการเชื่อมต่อ\n\n${e.toString()}';
      });
    }
  }

  Future<void> _reloadFromDatabase() async {
    try {
      final users = await DatabaseHelper.instance.getAllUsers();

      // Filter only pending members
      final pendingUsers = users
          .where((user) => user.status == 'Pending')
          .toList();

      final members = pendingUsers
          .map(
            (user) => {
              'Name': user.name,
              'Gmail': user.gmail,
              'Address': user.address,
              'VillageCode': user.villageCode,
              'PasswordHash': user.passwordHash,
              'Latitude': user.lat,
              'Longitude': user.lng,
              'Status': user.status,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _allMembers = members;
        });
      }
    } catch (e) {
      debugPrint('Error reloading from database: $e');
    }
  }

  Future<void> _updateStatus(String gmail, String newStatus) async {
    final appProvider = context.read<AppProvider>();

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                newStatus == 'Active' ? 'กำลังอนุมัติ...' : 'กำลังดำเนินการ...',
              ),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    bool ok = await SheetsService.instance.updateMemberStatus(
      appProvider.webAppUrl,
      gmail,
      newStatus,
    );

    if (ok) {
      // Update local database
      await DatabaseHelper.instance.updateUserStatus(gmail, newStatus);

      // Remove from pending list immediately
      setState(() {
        _allMembers.removeWhere((m) => m['Gmail'] == gmail);
      });

      if (mounted) {
        String msg = newStatus == 'Active'
            ? 'อนุมัติ $gmail สำเร็จ'
            : newStatus == 'Admin'
            ? 'ตั้ง $gmail เป็นผู้ดูแลแล้ว'
            : newStatus == 'Rejected'
            ? 'ปฏิเสธ $gmail แล้ว'
            : 'ปรับสถานะ $gmail สำเร็จ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $msg'),
            backgroundColor: newStatus == 'Rejected'
                ? Colors.orange
                : Colors.green,
          ),
        );
      }

      // Reload from database to ensure data is fresh
      await _reloadFromDatabase();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ไม่สามารถดำเนินการได้ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(String gmail, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการปฏิเสธ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการปฏิเสธการสมัครสมาชิกของ'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    gmail,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'หมายเหตุ: สมาชิกที่ถูกปฏิเสธจะไม่สามารถเข้าใช้งานระบบได้',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _updateStatus(gmail, 'Rejected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สมาชิกรอการอนุมัติ'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadMembers,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats row
          if (!_loading && _error.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'รออนุมัติ ${_allMembers.length} คน',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 64,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _loadMembers,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('รีเฟรช'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _allMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่มีสมาชิกรอการอนุมัติ 🎉',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMembers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allMembers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final m = _allMembers[i];

                        return Card(
                          elevation: 2,
                          color: cs.errorContainer.withAlpha(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.orange.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.orange.shade100,
                                      child: Text(
                                        (m['Name']?.toString() ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m['Name']?.toString() ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            m['Gmail']?.toString() ?? '-',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (m['Address'] != null &&
                                    m['Address'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.home_rounded,
                                          size: 14,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            m['Address'].toString(),
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
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _updateStatus(
                                          m['Gmail']?.toString() ?? '',
                                          'Active',
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('อนุมัติ'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade500,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _showRejectDialog(
                                          m['Gmail']?.toString() ?? '',
                                          m['Name']?.toString() ?? '',
                                        ),
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('ปฏิเสธ'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red.shade500,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
}
