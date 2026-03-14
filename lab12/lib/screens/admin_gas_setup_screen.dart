// lib/screens/admin_gas_setup_screen.dart
// Step 2 of Admin Config: Apps Script Setup & Web App URL input

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/gas_code_generator.dart';
import '../services/sheets_service.dart';
import '../services/hash_service.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';

class AdminGasSetupScreen extends StatefulWidget {
  final String spreadsheetId;

  const AdminGasSetupScreen({super.key, required this.spreadsheetId});

  @override
  State<AdminGasSetupScreen> createState() => _AdminGasSetupScreenState();
}

class _AdminGasSetupScreenState extends State<AdminGasSetupScreen> {
  final _webAppUrlCtrl = TextEditingController();
  bool _copied = false;
  bool _saving = false;

  @override
  void dispose() {
    _webAppUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String gasCode) async {
    await Clipboard.setData(ClipboardData(text: gasCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _onSave() async {
    final url = _webAppUrlCtrl.text.trim();

    // Validate Web App URL format
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ กรุณาวาง Web App URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!url.startsWith('https://script.google.com/macros/s/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ URL ไม่ถูกต้อง ต้องขึ้นต้นด้วย https://script.google.com/macros/s/',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!url.endsWith('/exec')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ URL ต้องลงท้ายด้วย /exec\n\nตัวอย่าง: https://script.google.com/macros/s/[ID]/exec',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    // Test connection before saving
    try {
      final testResult = await SheetsService.instance.fetchAllMembers(url);

      if (!mounted) return;

      // Connection successful - save config
      final ap = context.read<AppProvider>();
      final wasConfigured = ap.isConfigured;

      await ap.saveConfig(spreadsheetId: widget.spreadsheetId, webAppUrl: url);

      // Sync admin data to Admins sheet
      await _syncAdminData(url, ap);

      // Sync local database to Google Sheets
      await _syncLocalToSheets(url);

      setState(() => _saving = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ เชื่อมต่อสำเร็จ!\n'
            '• พบข้อมูลใน Sheets: ${testResult.length} รายการ\n'
            '• Sync ข้อมูล Local เรียบร้อย\n'
            '• บันทึกการตั้งค่าลง Local Database แล้ว',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      if (wasConfigured) {
        // Return to Profile/Settings
        Navigator.of(context).pop(); // Pop setup
        Navigator.of(context).pop(); // Pop initial config
      } else {
        // First time, go to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _saving = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ ไม่สามารถเชื่อมต่อได้\n\nกรุณาตรวจสอบ:\n• Deploy แล้วหรือยัง\n• Permission ตั้งเป็น "Anyone"\n• URL ถูกต้องหรือไม่\n\nError: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  /// Sync local database members to Google Sheets
  Future<void> _syncLocalToSheets(String webAppUrl) async {
    try {
      // Get all users from local database
      final localUsers = await DatabaseHelper.instance.getAllUsers();

      if (localUsers.isEmpty) {
        debugPrint('No local data to sync - creating empty table with headers');
        // Create empty table with headers only
        await _createEmptyTable(webAppUrl);
        return; // No local data to sync
      }

      debugPrint(
        'Syncing ${localUsers.length} users from local DB to Sheets...',
      );

      // Upload each user to Google Sheets
      int successCount = 0;
      int failCount = 0;

      for (final user in localUsers) {
        try {
          final success = await SheetsService.instance.registerMember(
            webAppUrl,
            user,
          );
          if (success) {
            successCount++;
            debugPrint('✓ Synced: ${user.gmail}');
          } else {
            failCount++;
            debugPrint('✗ Failed to sync: ${user.gmail}');
          }
        } catch (e) {
          failCount++;
          debugPrint('✗ Error syncing ${user.gmail}: $e');
        }
      }

      debugPrint('Sync complete: $successCount success, $failCount failed');

      // Clear sync queue after successful sync
      if (successCount > 0) {
        await DatabaseHelper.instance.clearSyncQueue();
        debugPrint('Cleared sync queue');
      }
    } catch (e) {
      // Silent fail - sync can be retried later
      debugPrint('Sync local to sheets failed: $e');
    }
  }

  /// Create empty table with headers only
  Future<void> _createEmptyTable(String webAppUrl) async {
    try {
      // Call initTable action to create headers only
      final success = await SheetsService.instance.initializeTable(webAppUrl);

      if (success) {
        debugPrint('✓ Created empty table with headers only');
      } else {
        debugPrint('⚠️ Failed to create empty table');
      }
    } catch (e) {
      debugPrint('Error creating empty table: $e');
    }
  }

  /// Sync admin data to Admins sheet
  Future<void> _syncAdminData(String webAppUrl, AppProvider ap) async {
    try {
      debugPrint('Syncing admin data to Admins sheet...');

      // Hash admin password before sending
      final passwordHash = HashService.hashPassword(ap.adminPassword);

      final adminData = {
        'action': 'addAdmin',
        'name': 'Admin',
        'gmail': ap.adminEmail,
        'passwordHash': passwordHash,
        'role': 'SuperAdmin',
        'villageCode': ap.adminVillageCode,
      };

      final response = await http
          .post(
            Uri.parse(webAppUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(adminData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'ok') {
          debugPrint('✓ Admin data synced successfully');
        } else {
          debugPrint('⚠️ Failed to sync admin data: ${body['message']}');
        }
      }
    } catch (e) {
      debugPrint('Error syncing admin data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gasCode = GasCodeGenerator.generate(widget.spreadsheetId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า Apps Script'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 3 & 4: Apps Script Code
              Text(
                '3. รับโค้ด: ระบบสร้างโค้ดให้แล้ว กรุณากดปุ่มเพื่อคัดลอก',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    gasCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFCDD6F4),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(gasCode),
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy_rounded,
                    color: _copied ? Colors.green : null,
                  ),
                  label: Text(
                    _copied ? '✅ คัดลอกแล้ว!' : '📋 คัดลอกโค้ด Apps Script',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _copied ? Colors.green : cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Step 4 Instructions
              Card(
                color: cs.tertiaryContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4. ติดตั้งสคริปต์:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ในหน้า Google Sheet ไปที่เมนู ส่วนขยาย (Extensions) > Apps Script จากนั้นลบโค้ดเก่าออกให้หมดแล้ววางโค้ดที่คัดลอกมาลงไป (อย่าลืมกดปุ่มบันทึกรูปแผ่นดิสก์)\n\n💡 หมายเหตุ: ไม่ต้องสร้างตารางหรือใส่ข้อมูลใน Sheet ระบบจะจัดการให้อัตโนมัติ',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step 5 Instructions
              Card(
                color: cs.primaryContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5. เปิดการใช้งาน (สำคัญมาก):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กดปุ่ม การทำให้ใช้งานได้ (Deploy) > รายการใหม่ (New Deployment) โดยตั้งค่าดังนี้:\n'
                        '• ประเภท: เลือกเป็น "เว็บแอป" (Web App)\n'
                        '• ดำเนินการในฐานะ: เลือกเป็น "ฉัน" (Me)\n'
                        '• ผู้ที่มีสิทธิ์เข้าถึง: เลือกเป็น "ทุกคน" (Anyone) เท่านั้น',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onPrimaryContainer,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Step 6 Input
              Text(
                '6. เสร็จสมบูรณ์: วาง Web App URL ที่ได้',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '⚠️ URL ต้องลงท้ายด้วย /exec เท่านั้น',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _webAppUrlCtrl,
                decoration: InputDecoration(
                  hintText: 'https://script.google.com/macros/s/.../exec',
                  prefixIcon: const Icon(Icons.rocket_launch_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  helperText:
                      'ตัวอย่าง: https://script.google.com/macros/s/AKfycby.../exec',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 24),

              // Final Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _onSave,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _saving ? 'กำลังบันทึก...' : 'บันทึกและเริ่มใช้งาน',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
