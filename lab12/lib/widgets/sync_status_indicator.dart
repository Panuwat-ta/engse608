// lib/widgets/sync_status_indicator.dart
// Widget to show sync status

import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncStatusIndicator extends StatelessWidget {
  final String webAppUrl;

  const SyncStatusIndicator({super.key, required this.webAppUrl});

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
          Icon(Icons.sync_rounded, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Auto-sync เปิดใช้งาน (ทุก 1 นาที)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await SyncService.instance.manualSync(webAppUrl);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? '✅ Sync สำเร็จ: ${result.totalSynced} รายการ'
                          : '❌ ${result.message}',
                    ),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Sync ทันที', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
