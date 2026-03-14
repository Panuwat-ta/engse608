// lib/screens/register_screen.dart
// Registration form with password, GPS pickup, and offline sync

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';
import '../services/sheets_service.dart';
import '../services/location_service.dart';
import '../services/hash_service.dart';

class RegisterScreen extends StatefulWidget {
  final String? prefillGmail;

  const RegisterScreen({super.key, this.prefillGmail});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _gmailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCodeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  double? _lat;
  double? _lng;
  bool _fetchingGps = false;
  bool _saving = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _gpsStatus = 'ยังไม่ได้ดึงพิกัด';

  @override
  void initState() {
    super.initState();
    if (widget.prefillGmail != null) {
      _gmailCtrl.text = widget.prefillGmail!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gmailCtrl.dispose();
    _addressCtrl.dispose();
    _villageCodeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    setState(() {
      _fetchingGps = true;
      _gpsStatus = 'กำลังดึงพิกัด GPS...';
    });
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _gpsStatus =
            'ละติจูด: ${pos.latitude.toStringAsFixed(6)}\n'
            'ลองจิจูด: ${pos.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() => _gpsStatus = '❌ ${e.toString()}');
    } finally {
      setState(() => _fetchingGps = false);
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาดึงพิกัด GPS ก่อนสมัคร'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final appProvider = context.read<AppProvider>();

    // Hash password before saving
    final passwordHash = HashService.hashPassword(_passwordCtrl.text);

    final user = UserModel(
      name: _nameCtrl.text.trim(),
      gmail: _gmailCtrl.text.trim().toLowerCase(),
      address: _addressCtrl.text.trim(),
      villageCode: _villageCodeCtrl.text.trim(),
      passwordHash: passwordHash,
      lat: _lat!,
      lng: _lng!,
      status: 'Pending',
    );

    // 1. Save to SQLite
    await DatabaseHelper.instance.insertUser(user);

    // 2. Try to sync to Google Sheet
    bool synced = false;
    if (appProvider.webAppUrl.isNotEmpty) {
      synced = await SheetsService.instance.registerMember(
        appProvider.webAppUrl,
        user,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final msg = synced
        ? '✅ สมัครสำเร็จ! รอ Admin อนุมัติ'
        : '✅ บันทึกแล้ว (จะ sync เมื่อเชื่อมต่อ)';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 40,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal Info ──────────────────────────────────────────────
              _label('ชื่อ-นามสกุล', context),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _decor('กรอกชื่อ-นามสกุล', Icons.badge_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),

              _label('Gmail', context),
              const SizedBox(height: 6),
              TextFormField(
                controller: _gmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decor('example@gmail.com', Icons.email_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'กรุณากรอก Gmail';
                  if (!v.contains('@')) return 'Gmail ไม่ถูกต้อง';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('ที่อยู่', context),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: _decor('กรอกที่อยู่', Icons.home_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกที่อยู่' : null,
              ),
              const SizedBox(height: 16),

              _label('รหัสหมู่บ้าน(ขอจากผู้ดูแลหมู่บ้าน)', context),
              const SizedBox(height: 6),
              TextFormField(
                controller: _villageCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _decor(
                  'เช่น MOO001 หรือ หมู่ 5',
                  Icons.location_city_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณากรอกรหัสหมู่บ้าน'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Password ───────────────────────────────────────────────────
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lock_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'ตั้งรหัสผ่าน',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _label('รหัสผ่าน', context),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: 'อย่างน้อย 6 ตัวอักษร',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                  if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('ยืนยันรหัสผ่าน', context),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสผ่านอีกครั้ง',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) return 'รหัสผ่านไม่ตรงกัน';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 20),

              // ── GPS ────────────────────────────────────────────────────────
              const Divider(),
              const SizedBox(height: 12),
              _label('พิกัด GPS', context),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gpsStatus,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: _lat != null ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _fetchingGps ? null : _fetchGps,
                        icon: _fetchingGps
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                        label: Text(
                          _fetchingGps
                              ? 'กำลังดึงพิกัด...'
                              : '📍 ดึงพิกัด GPS อัตโนมัติ',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _onRegister,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.how_to_reg_rounded),
                  label: Text(_saving ? 'กำลังบันทึก...' : 'สมัครสมาชิก'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'หลังสมัครแล้วรอ Admin อนุมัติก่อนใช้งาน',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _decor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
