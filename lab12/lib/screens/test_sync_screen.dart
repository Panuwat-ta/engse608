// lib/screens/test_sync_screen.dart
// Test and debug sync functionality

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class TestSyncScreen extends StatefulWidget {
  const TestSyncScreen({super.key});

  @override
  State<TestSyncScreen> createState() => _TestSyncScreenState();
}

class _TestSyncScreenState extends State<TestSyncScreen> {
  String _log = '';
  bool _testing = false;

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    debugPrint(message);
  }

  Future<void> _runTest() async {
    setState(() {
      _log = '';
      _testing = true;
    });

    final appProvider = context.read<AppProvider>();

    _addLog('=== เริ่มทดสอบ Sync ===');
    _addLog('');

    // Test 1: Check config
    _addLog('📋 ตรวจสอบการตั้งค่า...');
    _addLog('Spreadsheet ID: ${appProvider.spreadsheetId}');
    _addLog('Web App URL: ${appProvider.webAppUrl}');

    if (appProvider.webAppUrl.isEmpty) {
      _addLog('❌ ยังไม่ได้ตั้งค่า Web App URL');
      setState(() => _testing = false);
      return;
    }
    _addLog('✅ การตั้งค่าถูกต้อง');
    _addLog('');

    // Test 2: Check local database
    _addLog('📋 ตรวจสอบ Local Database...');
    try {
      final localUsers = await DatabaseHelper.instance.getAllUsers();
      _addLog('พบข้อมูลใน Local DB: ${localUsers.length} รายการ');

      if (localUsers.isEmpty) {
        _addLog('⚠️ Local Database ว่างเปล่า - ยังไม่มีสมาชิกลงทะเบียน');
        _addLog('');
        _addLog('💡 ทดสอบสร้างข้อมูลตัวอย่าง...');
        await _createTestData();
        return;
      }

      for (var user in localUsers) {
        _addLog('  • ${user.name} (${user.gmail}) - ${user.status}');
      }
      _addLog('✅ พบข้อมูลใน Local DB');
      _addLog('');

      // Test 3: Test connection
      _addLog('📋 ทดสอบการเชื่อมต่อ Google Sheets...');
      try {
        final sheetMembers = await SheetsService.instance.fetchAllMembers(
          appProvider.webAppUrl,
        );
        _addLog('พบข้อมูลใน Sheets: ${sheetMembers.length} รายการ');
        _addLog('✅ เชื่อมต่อ Google Sheets สำเร็จ');
        _addLog('');

        // Test 4: Sync data
        _addLog('📋 เริ่ม Sync ข้อมูล...');
        int successCount = 0;
        int failCount = 0;

        for (var user in localUsers) {
          try {
            final success = await SheetsService.instance.registerMember(
              appProvider.webAppUrl,
              user,
            );
            if (success) {
              successCount++;
              _addLog('  ✓ Sync สำเร็จ: ${user.gmail}');
            } else {
              failCount++;
              _addLog('  ✗ Sync ล้มเหลว: ${user.gmail}');
            }
          } catch (e) {
            failCount++;
            _addLog('  ✗ Error: ${user.gmail} - $e');
          }
        }

        _addLog('');
        _addLog('=== สรุปผลการ Sync ===');
        _addLog('✅ สำเร็จ: $successCount รายการ');
        _addLog('❌ ล้มเหลว: $failCount รายการ');

        if (successCount > 0) {
          _addLog('');
          _addLog('🎉 Sync เสร็จสมบูรณ์!');
        }
      } catch (e) {
        _addLog('❌ ไม่สามารถเชื่อมต่อ Google Sheets: $e');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _testing = false);
  }

  Future<void> _createTestData() async {
    try {
      final testUser = UserModel(
        name: 'ทดสอบระบบ',
        gmail: 'test@example.com',
        address: '123 ถนนทดสอบ',
        villageCode: 'TEST001',
        passwordHash: 'test123',
        lat: 13.7563,
        lng: 100.5018,
        status: 'Pending',
      );

      await DatabaseHelper.instance.insertUser(testUser);
      _addLog('✅ สร้างข้อมูลทดสอบสำเร็จ');
      _addLog('');
      _addLog('💡 กรุณากดปุ่ม "ทดสอบ Sync" อีกครั้ง');
    } catch (e) {
      _addLog('❌ ไม่สามารถสร้างข้อมูลทดสอบ: $e');
    }

    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ทดสอบ Sync'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _testing ? null : _runTest,
                icon: _testing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_testing ? 'กำลังทดสอบ...' : 'เริ่มทดสอบ Sync'),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _log.isEmpty
                      ? 'กดปุ่ม "เริ่มทดสอบ Sync" เพื่อเริ่มการทดสอบ'
                      : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFCDD6F4),
                    height: 1.5,
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
