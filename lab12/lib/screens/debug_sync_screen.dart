// lib/screens/debug_sync_screen.dart
// Debug screen to test sync functionality

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sync_service.dart';
import '../services/sheets_service.dart';
import '../database/database_helper.dart';

class DebugSyncScreen extends StatefulWidget {
  const DebugSyncScreen({super.key});

  @override
  State<DebugSyncScreen> createState() => _DebugSyncScreenState();
}

class _DebugSyncScreenState extends State<DebugSyncScreen> {
  String _log = '';
  bool _loading = false;

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toString().substring(11, 19)} $message\n';
    });
  }

  Future<void> _testDirectFetch() async {
    setState(() {
      _loading = true;
      _log = '';
    });

    final appProvider = context.read<AppProvider>();
    _addLog('🔍 Testing direct fetch from Sheets...');
    _addLog('Web App URL: ${appProvider.webAppUrl}');

    try {
      final members = await SheetsService.instance.fetchAllMembers(
        appProvider.webAppUrl,
      );

      _addLog('✅ Direct fetch result: ${members.length} members');

      for (int i = 0; i < members.length && i < 5; i++) {
        final member = members[i];
        _addLog('  Member ${i + 1}: ${member['Name']} (${member['Status']})');
      }

      if (members.length > 5) {
        _addLog('  ... and ${members.length - 5} more');
      }
    } catch (e) {
      _addLog('❌ Direct fetch error: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _testLocalDatabase() async {
    setState(() {
      _loading = true;
      _log = '';
    });

    _addLog('🗄️ Testing Local Database...');

    try {
      final users = await DatabaseHelper.instance.getAllUsers();
      _addLog('✅ Local DB result: ${users.length} users');

      for (int i = 0; i < users.length && i < 5; i++) {
        final user = users[i];
        _addLog('  User ${i + 1}: ${user.name} (${user.status})');
      }

      if (users.length > 5) {
        _addLog('  ... and ${users.length - 5} more');
      }
    } catch (e) {
      _addLog('❌ Local DB error: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _testFullSync() async {
    setState(() {
      _loading = true;
      _log = '';
    });

    final appProvider = context.read<AppProvider>();
    _addLog('🔄 Testing full sync...');

    try {
      final result = await SyncService.instance.manualSync(
        appProvider.webAppUrl,
      );

      _addLog('✅ Sync result: ${result.success}');
      _addLog('   Message: ${result.message}');
      _addLog('   Users synced: ${result.usersSynced}');
      _addLog('   Pending synced: ${result.pendingSynced}');

      // Check local DB after sync
      final users = await DatabaseHelper.instance.getAllUsers();
      _addLog('📊 Local DB after sync: ${users.length} users');
    } catch (e) {
      _addLog('❌ Sync error: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _clearLocalDatabase() async {
    setState(() {
      _loading = true;
      _log = '';
    });

    _addLog('🗑️ Clearing Local Database...');

    try {
      // Clear all users
      final users = await DatabaseHelper.instance.getAllUsers();
      for (final user in users) {
        await DatabaseHelper.instance.deleteUser(user.gmail);
      }

      _addLog('✅ Cleared ${users.length} users from Local DB');

      // Verify
      final remainingUsers = await DatabaseHelper.instance.getAllUsers();
      _addLog('📊 Remaining users: ${remainingUsers.length}');
    } catch (e) {
      _addLog('❌ Clear error: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Sync'), centerTitle: true),
      body: Column(
        children: [
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _testDirectFetch,
                        child: const Text('Test Sheets'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _testLocalDatabase,
                        child: const Text('Test Local DB'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _testFullSync,
                        child: const Text('Test Full Sync'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _clearLocalDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear Local DB'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _log = ''),
                    child: const Text('Clear Log'),
                  ),
                ),
              ],
            ),
          ),

          // Log display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'กำลังทดสอบ...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _log.isEmpty ? 'กดปุ่มด้านบนเพื่อทดสอบ' : _log,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
