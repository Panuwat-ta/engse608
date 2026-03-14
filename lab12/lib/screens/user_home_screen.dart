// lib/screens/user_home_screen.dart
// Logged-in user home: shows status (Pending / Active) with refreshable info

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  bool _refreshing = false;

  Future<void> _refreshStatus() async {
    setState(() => _refreshing = true);
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user == null) return;

    // Check status from Sheet
    if (appProvider.webAppUrl.isNotEmpty) {
      final sheetData = await SheetsService.instance
          .checkUser(appProvider.webAppUrl, user.gmail);
      if (sheetData != null) {
        final newStatus = sheetData['Status']?.toString() ?? user.status;
        await DatabaseHelper.instance.updateUserStatus(user.gmail, newStatus);
        appProvider.updateCurrentUserStatus(newStatus);
      }
    }
    if (mounted) setState(() => _refreshing = false);
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
    final user = appProvider.currentUser;
    if (user == null) return const SizedBox();

    final isPending = user.status == 'Pending';

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
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('หน้าหลัก'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'ออกจากระบบ',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                _StatusBanner(isPending: isPending, cs: cs),
                const SizedBox(height: 24),
    
                // Profile card
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(user.gmail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        _InfoRow(icon: Icons.home_rounded, label: 'ที่อยู่', value: user.address),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.location_city_rounded,
                            label: 'รหัสหมู่บ้าน',
                            value: user.villageCode.isNotEmpty
                                ? user.villageCode
                                : '-'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'พิกัด',
                            value:
                                '${user.lat.toStringAsFixed(5)}, ${user.lng.toStringAsFixed(5)}'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.verified_rounded,
                            label: 'สถานะ',
                            value: user.status,
                            valueColor:
                                isPending ? Colors.orange : Colors.green),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
    
                // Refresh status button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _refreshing ? null : _refreshStatus,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('ตรวจสอบสถานะล่าสุด'),
                  ),
                ),
    
                if (!isPending) ...[
                  const SizedBox(height: 28),
                  Text('ฟีเจอร์ยืม-คืนอุปกรณ์',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant,
                          )),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.handshake_rounded,
                    title: 'ยืมอุปกรณ์',
                    subtitle: 'เร็วๆ นี้',
                    cs: cs,
                  ),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.assignment_return_rounded,
                    title: 'คืนอุปกรณ์',
                    subtitle: 'เร็วๆ นี้',
                    cs: cs,
                  ),
                ],
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

class _StatusBanner extends StatelessWidget {
  final bool isPending;
  final ColorScheme cs;

  const _StatusBanner({required this.isPending, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPending
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.green.shade400, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPending ? Colors.orange : Colors.green).withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? '⏳ รอการอนุมัติ' : '✅ ได้รับการอนุมัติแล้ว',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isPending
                      ? 'Admin จะอนุมัติบัญชีของคุณเร็วๆ นี้'
                      : 'คุณสามารถใช้งานระบบยืม-คืนได้แล้ว',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;

  const _FeatureCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title),
        subtitle: Text(subtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () {}, // future feature
      ),
    );
  }
}
