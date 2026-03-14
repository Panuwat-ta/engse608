// lib/screens/admin_config_screen.dart
// Zero-Config setup: Admin pastes Sheet URL → Gets GAS code to deploy
// Also shows connection info when already configured

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../database/database_helper.dart';
import 'admin_gas_setup_screen.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  bool _isSaving = false;
  Map<String, String> _configData = {};
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfigData();
  }

  Future<void> _loadConfigData() async {
    setState(() => _loadingConfig = true);
    try {
      final config = await DatabaseHelper.instance.getAllConfig();
      setState(() {
        _configData = config;
        _loadingConfig = false;
      });
    } catch (e) {
      setState(() => _loadingConfig = false);
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final url = _urlCtrl.text.trim();
    final spreadsheetId = AppProvider.extractSpreadsheetId(url);

    if (spreadsheetId == null || spreadsheetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ ไม่พบ Spreadsheet ID ในลิงก์ กรุณาตรวจสอบ URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Save spreadsheet ID; web app URL will be added after GAS deploy
    await context.read<AppProvider>().saveConfig(
      spreadsheetId: spreadsheetId,
      webAppUrl: '', // Admin will paste after deploying GAS
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    // Proceed to Step 2: Apps Script Setup
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminGasSetupScreen(spreadsheetId: spreadsheetId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appProvider = context.watch<AppProvider>();
    final isConnected = appProvider.isConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่าระบบ'), centerTitle: true),
      body: _loadingConfig
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: isConnected
                    ? _buildConnectedView(context, cs, appProvider)
                    : _buildSetupView(context, cs),
              ),
            ),
    );
  }

  // View when already connected
  Widget _buildConnectedView(
    BuildContext context,
    ColorScheme cs,
    AppProvider appProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 44,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'เชื่อมต่อสำเร็จ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Config table
        Text(
          'ตารางการตั้งค่าแอป (app_config)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'ข้อมูลการเชื่อมต่อที่บันทึกใน Local Database',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        // Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'config_key',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'config_value',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Data rows
              if (_configData.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ไม่มีข้อมูล',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else
                ..._configData.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: cs.outline.withAlpha(128)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Reconnect button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ยืนยันการเชื่อมต่อใหม่'),
                  content: const Text(
                    'คุณต้องการเชื่อมต่อ Google Sheet ใหม่หรือไม่?\n\n'
                    'การตั้งค่าเดิมจะถูกแทนที่',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('ยกเลิก'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('ยืนยัน'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                // Clear config and reload
                await DatabaseHelper.instance.clearAllConfig();
                await appProvider.saveConfig(spreadsheetId: '', webAppUrl: '');
                setState(() {
                  _configData = {};
                });
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('เชื่อมต่อใหม่'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.primary),
            ),
          ),
        ),
      ],
    );
  }

  // View when not connected (setup)
  Widget _buildSetupView(BuildContext context, ColorScheme cs) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings_rounded, size: 44, color: cs.primary),
            ),
          ),
          Center(
            child: Text(
              'เชื่อมต่อ Google Sheet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 36),

          // Instructions card
          Card(
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'วิธีใช้งาน',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...[
                    '1. เตรียมพื้นที่: สร้าง Google Sheet ใหม่ (Sheet เปล่าๆ ไม่ต้องใส่ข้อมูลอะไร) แล้วคัดลอก URL ของหน้าเว็บนั้นมาเตรียมไว้',
                    '2. เชื่อมต่อลิงก์: นำลิงก์ที่คัดลอกมาวางในช่อง "Google Sheet URL" ด้านล่างนี้ แล้วกดปุ่ม "ถัดไป"',
                    '💡 หมายเหตุ: ระบบจะสร้างตารางและจัดการข้อมูลให้อัตโนมัติ',
                  ].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: cs.onSecondaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // URL Input
          Text(
            'Google Sheet URL',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://docs.google.com/spreadsheets/d/...',
              prefixIcon: const Icon(Icons.link_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'กรุณาวาง Google Sheet URL';
              }
              if (!v.contains('docs.google.com/spreadsheets')) {
                return 'URL ไม่ถูกต้อง — ต้องเป็นลิงก์ Google Sheet';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _onConfirm,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isSaving ? 'กำลังประมวลผล...' : 'ถัดไป — รับโค้ด Apps Script',
              ),
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
