// lib/screens/rejected_members_screen.dart
// Admin view: list of Rejected members with option to re-approve

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';

class RejectedMembersScreen extends StatefulWidget {
  const RejectedMembersScreen({super.key});

  @override
  State<RejectedMembersScreen> createState() => _RejectedMembersScreenState();
}

class _RejectedMembersScreenState extends State<RejectedMembersScreen> {
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

      // Filter only rejected members
      final rejectedUsers = users
          .where((user) => user.status == 'Rejected')
          .toList();

      // Convert UserModel to Map format for compatibility
      final members = rejectedUsers
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
              'ไม่มีสมาชิกที่ถูกปฏิเสธ\n\n'
              'หน้านี้แสดงรายชื่อสมาชิกที่ถูกปฏิเสธ\n'
              '(สถานะ Rejected)';
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

      // Filter only rejected members
      final rejectedUsers = users
          .where((user) => user.status == 'Rejected')
          .toList();

      final members = rejectedUsers
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

      // Remove from rejected list immediately
      setState(() {
        _allMembers.removeWhere((m) => m['Gmail'] == gmail);
      });

      if (mounted) {
        String msg = newStatus == 'Active'
            ? 'อนุมัติ $gmail สำเร็จ'
            : newStatus == 'Admin'
            ? 'ตั้ง $gmail เป็นผู้ดูแลแล้ว'
            : newStatus == 'Pending'
            ? 'ย้าย $gmail กลับไปรอการอนุมัติ'
            : 'ปรับสถานะ $gmail สำเร็จ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $msg'), backgroundColor: Colors.green),
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

  Future<void> _showApproveDialog(String gmail, String name) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('อนุมัติสมาชิก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการอนุมัติสมาชิกที่ถูกปฏิเสธ'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
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
              'เลือกสถานะใหม่:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('Pending'),
            child: const Text('ย้ายไปรอการอนุมัติ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('Active'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateStatus(gmail, result);
    }
  }

  Future<void> _showDeleteDialog(String gmail, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบผู้ใช้'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบสมาชิกคนนี้ออกจากระบบ'),
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
              '⚠️ การดำเนินการนี้ไม่สามารถยกเลิกได้',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ข้อมูลสมาชิกจะถูกลบออกจากระบบทั้งหมด',
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
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
      await _deleteUser(gmail, name);
    }
  }

  Future<void> _deleteUser(String gmail, String name) async {
    final appProvider = context.read<AppProvider>();

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('กำลังลบผู้ใช้...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Delete from Google Sheets first
      bool sheetDeleted = false;
      if (appProvider.webAppUrl.isNotEmpty) {
        sheetDeleted = await SheetsService.instance.deleteUser(
          appProvider.webAppUrl,
          gmail,
        );
      }

      // Delete from local database
      final localDeleted = await DatabaseHelper.instance.deleteUser(gmail);

      if (sheetDeleted || localDeleted > 0) {
        // Remove from list immediately
        setState(() {
          _allMembers.removeWhere((m) => m['Gmail'] == gmail);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ลบผู้ใช้ $name สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload from database to ensure data is fresh
        await _reloadFromDatabase();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ ไม่สามารถลบผู้ใช้ได้ กรุณาลองใหม่'),
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
        title: const Text('สมาชิกที่ถูกปฏิเสธ'),
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
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ถูกปฏิเสธ ${_allMembers.length} คน',
                      style: const TextStyle(
                        color: Colors.red,
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
                          'ไม่มีสมาชิกที่ถูกปฏิเสธ 🎉',
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
                          color: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.red.shade300),
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
                                      backgroundColor: Colors.red.shade100,
                                      child: Text(
                                        (m['Name']?.toString() ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade800,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'ถูกปฏิเสธ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _showDeleteDialog(
                                        m['Gmail']?.toString() ?? '',
                                        m['Name']?.toString() ?? '',
                                      ),
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      tooltip: 'ลบผู้ใช้',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
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
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _showApproveDialog(
                                      m['Gmail']?.toString() ?? '',
                                      m['Name']?.toString() ?? '',
                                    ),
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('พิจารณาใหม่'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.blue.shade500,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
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
