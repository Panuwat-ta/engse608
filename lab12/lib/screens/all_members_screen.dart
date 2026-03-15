// lib/screens/all_members_screen.dart
// Screen to display all approved members (Active and Admin status)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';

class AllMembersScreen extends StatefulWidget {
  const AllMembersScreen({super.key});

  @override
  State<AllMembersScreen> createState() => _AllMembersScreenState();
}

class _AllMembersScreenState extends State<AllMembersScreen> {
  List<Map<String, dynamic>> _allMembers = [];
  bool _loading = true;
  String _error = '';
  // Removed filter since we only show Active members

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

      // Filter only Active members (exclude Admin)
      final approvedUsers = users
          .where((user) => user.status == 'Active')
          .toList();

      // Convert UserModel to Map format for compatibility
      final members = approvedUsers
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
              'ยังไม่มีสมาชิกที่อนุมัติแล้ว\n\n'
              'หน้านี้แสดงรายชื่อสมาชิกที่ได้รับการอนุมัติแล้ว\n'
              '(สถานะ Active เท่านั้น)';
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

      // Filter only Active members (exclude Admin)
      final approvedUsers = users
          .where((user) => user.status == 'Active')
          .toList();

      final members = approvedUsers
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

  // No filtering needed since we only load Active members

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สมาชิกทั้งหมด'),
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
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'สมาชิก ${_allMembers.length} คน',
                      style: const TextStyle(
                        color: Colors.green,
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
                          Icons.inbox_rounded,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่มีข้อมูล',
                          style: TextStyle(color: cs.onSurfaceVariant),
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
                          elevation: 0,
                          color: cs.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                                      backgroundColor: Colors.green.shade100,
                                      child: Text(
                                        (m['Name']?.toString() ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
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
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
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

// Removed _StatChip and _StatusBadge widgets since we only show Active members
