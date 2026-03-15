// lib/screens/admin_home_screen.dart
// Admin dashboard: stats, quick actions, member management

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';
import 'admin_config_screen.dart';
import 'pending_members_screen.dart';
import 'rejected_members_screen.dart';
import 'all_members_screen.dart';
import 'admin_profile_screen.dart';
import 'manage_transactions_screen.dart';
import 'manage_equipment_screen.dart';
import 'pending_returns_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalCount = 0;
  int _pendingCount = 0;
  int _activeCount = 0;
  int _rejectedCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final appProvider = context.read<AppProvider>();

    try {
      // Load from Local Database first (instant display)
      final localUsers = await DatabaseHelper.instance.getAllUsers();
      final localEquipment = await DatabaseHelper.instance.getAllEquipment();

      setState(() {
        _totalCount = localUsers.length;
        _pendingCount = localUsers.where((u) => u.status == 'Pending').length;
        _activeCount = localUsers.where((u) => u.status == 'Active').length;
        _rejectedCount = localUsers.where((u) => u.status == 'Rejected').length;
        _loading = false;
      });

      // If Local DB is empty and URL is configured, force sync
      if (appProvider.webAppUrl.isNotEmpty) {
        if (localUsers.isEmpty || localEquipment.isEmpty) {
          debugPrint('⚠️ Local DB is empty, forcing sync...');
          final result = await SyncService.instance.manualSync(
            appProvider.webAppUrl,
          );
          if (mounted && result.success) {
            _reloadStats();
          }
        } else {
          // Normal background sync
          SyncService.instance.manualSync(appProvider.webAppUrl).then((result) {
            if (mounted && result.success && result.usersSynced > 0) {
              _reloadStats();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _reloadStats() async {
    try {
      final localUsers = await DatabaseHelper.instance.getAllUsers();
      if (mounted) {
        setState(() {
          _totalCount = localUsers.length;
          _pendingCount = localUsers.where((u) => u.status == 'Pending').length;
          _activeCount = localUsers.where((u) => u.status == 'Active').length;
          _rejectedCount = localUsers
              .where((u) => u.status == 'Rejected')
              .length;
        });
      }
    } catch (e) {
      debugPrint('Error reloading stats: $e');
    }
  }

  Future<void> _syncAndRefresh() async {
    final appProvider = context.read<AppProvider>();

    if (appProvider.webAppUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ ยังไม่ได้ตั้งค่า Web App URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show syncing indicator
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
            Text('กำลัง Sync ข้อมูลทั้งหมด...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Perform sync in background
      final result = await SyncService.instance.manualSync(
        appProvider.webAppUrl,
      );

      if (!mounted) return;

      if (result.success) {
        // Show detailed success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.detailMessage}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reload stats after sync
        await _reloadStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _logout() {
    context.read<AppProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appProvider = context.watch<AppProvider>();
    final adminGmail = appProvider.adminEmail;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog();
        if (shouldPop ?? false) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('แผงควบคุม Admin'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              ),
              icon: const Icon(Icons.account_circle_rounded),
              tooltip: 'โปรไฟล์และตั้งค่า',
            ),
            IconButton(
              onPressed: _syncAndRefresh,
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sync และรีเฟรช',
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'ออกจากระบบ',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _syncAndRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1565C0), // Dark blue
                        const Color(0xFF0D47A1), // Darker blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminProfileScreen(),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Profile image or icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            shape: BoxShape.circle,
                            image: appProvider.adminProfileImagePath.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(
                                      File(appProvider.adminProfileImagePath),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(
                              color: Colors.white.withAlpha(100),
                              width: 2,
                            ),
                          ),
                          child: appProvider.adminProfileImagePath.isEmpty
                              ? const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 32,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ยินดีต้อนรับ, Admin',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                adminGmail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (appProvider.adminVillageCode.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.home_work_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'รหัสหมู่บ้าน: ${appProvider.adminVillageCode}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats row
                Text(
                  'สรุปสถิติ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'ทั้งหมด',
                              value: _totalCount,
                              icon: Icons.group_rounded,
                              color: cs.primary,
                              cs: cs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'รออนุมัติ',
                              value: _pendingCount,
                              icon: Icons.hourglass_top_rounded,
                              color: Colors.orange,
                              cs: cs,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'อนุมัติแล้ว',
                              value: _activeCount,
                              icon: Icons.check_circle_rounded,
                              color: Colors.green,
                              cs: cs,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'การจัดการ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Pending members
                _ActionCard(
                  icon: Icons.people_alt_rounded,
                  title: 'สมาชิกรอการอนุมัติ',
                  subtitle: _pendingCount > 0
                      ? '$_pendingCount คน รอการอนุมัติ'
                      : 'ไม่มีรายการรออนุมัติ',
                  badge: _pendingCount > 0 ? '$_pendingCount' : null,
                  color: Colors.orange,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PendingMembersScreen(),
                      ),
                    );
                    _loadStats();
                  },
                ),
                const SizedBox(height: 10),

                // All approved members
                _ActionCard(
                  icon: Icons.manage_accounts_rounded,
                  title: 'สมาชิกทั้งหมด',
                  subtitle: 'ดูสมาชิกที่อนุมัติแล้ว $_activeCount คน',
                  badge: null,
                  color: cs.primary,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AllMembersScreen(),
                      ),
                    );
                    _loadStats();
                  },
                ),
                const SizedBox(height: 10),

                // Rejected members
                _ActionCard(
                  icon: Icons.person_off_rounded,
                  title: 'สมาชิกที่ถูกปฏิเสธ',
                  subtitle: _rejectedCount > 0
                      ? 'มีสมาชิกที่ถูกปฏิเสธ $_rejectedCount คน'
                      : 'ไม่มีสมาชิกที่ถูกปฏิเสธ',
                  badge: _rejectedCount > 0 ? '$_rejectedCount' : null,
                  color: Colors.red,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RejectedMembersScreen(),
                      ),
                    );
                    _loadStats();
                  },
                ),
                const SizedBox(height: 10),

                // Equipment management
                _ActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'จัดการอุปกรณ์',
                  subtitle: 'เพิ่ม แก้ไข ลบอุปกรณ์',
                  badge: null,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageEquipmentScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Transaction management
                _ActionCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'สถานะการยืม',
                  subtitle: 'ดูรายการยืม-คืนอุปกรณ์',
                  badge: null,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageTransactionsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Pending returns approval
                _ActionCard(
                  icon: Icons.assignment_return_rounded,
                  title: 'รอการยืนยันการคืน',
                  subtitle: 'อนุมัติการคืนอุปกรณ์',
                  badge: null,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PendingReturnsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Reconfigure Sheet
                _ActionCard(
                  icon: Icons.settings_rounded,
                  title: 'ตั้งค่า Google Sheet',
                  subtitle: appProvider.isConfigured
                      ? 'ID: ${appProvider.spreadsheetId.substring(0, 12)}...'
                      : 'ยังไม่ได้ตั้งค่า',
                  badge: null,
                  color: cs.secondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminConfigScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Connection info
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_done_rounded,
                              color: appProvider.webAppUrl.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'การเชื่อมต่อ',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Google Sheets: ${appProvider.webAppUrl.isNotEmpty ? "เชื่อมต่อแล้ว ✅" : "ยังไม่ได้ตั้งค่า ❌"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันที่จะปิดแอป'),
          ],
        ),
        content: const Text('คุณต้องการปิดแอปพลิเคชันใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ปิดแอป'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
