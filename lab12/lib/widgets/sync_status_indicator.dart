// lib/widgets/sync_status_indicator.dart
// Widget to show sync status

import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncStatusIndicator extends StatefulWidget {
  final String webAppUrl;
  final VoidCallback? onSyncComplete;

  const SyncStatusIndicator({
    super.key,
    required this.webAppUrl,
    this.onSyncComplete,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    if (_isSyncing) {
      // If already syncing, show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Sync กำลังทำงานอยู่ กรุณารอสักครู่'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final result = await SyncService.instance.manualSync(widget.webAppUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '✅ ${result.detailMessage}'
                  : '❌ ${result.message}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: Duration(seconds: result.success ? 3 : 2),
          ),
        );

        // Call callback to refresh the screen
        if (result.success && widget.onSyncComplete != null) {
          widget.onSyncComplete!();
        }
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
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          _isSyncing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                  ),
                )
              : Icon(Icons.sync_rounded, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSyncing
                  ? 'กำลัง Sync...'
                  : 'Auto-sync เปิดใช้งาน (ทุก 1 นาที)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _isSyncing ? null : _handleSync,
            child: Text(
              _isSyncing ? 'กำลัง Sync...' : 'Sync ทันที',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
