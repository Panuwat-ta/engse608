// lib/screens/force_update_admin_credentials_screen.dart
// Mandatory screen for admins still using default credentials

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'pin_setup_screen.dart';
import 'admin_home_screen.dart';

class ForceUpdateAdminCredentialsScreen extends StatefulWidget {
  const ForceUpdateAdminCredentialsScreen({super.key});

  @override
  State<ForceUpdateAdminCredentialsScreen> createState() =>
      _ForceUpdateAdminCredentialsScreenState();
}

class _ForceUpdateAdminCredentialsScreenState
    extends State<ForceUpdateAdminCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _villageCodeCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final ap = context.read<AppProvider>();

    await ap.saveAdminCredentials(
      newEmail: _emailCtrl.text.trim(),
      newPassword: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    // After updating, proceed to PIN setup or Home
    if (!ap.hasPin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // Prevent going back
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ตั้งค่าบัญชีแอดมิน'),
          centerTitle: true,
          automaticallyImplyLeading: false, // Hide back button
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: cs.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'เพื่อความปลอดภัย กรุณาเปลี่ยนอีเมลและรหัสผ่านจากค่าเริ่มต้นก่อนเริ่มใช้งานระบบ',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // New Email
                  Text(
                    'อีเมลใหม่ที่ต้องการใช้',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'example@gmail.com',
                      prefixIcon: const Icon(Icons.email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'กรุณากรอกอีเมล';
                      if (!v.contains('@')) return 'อีเมลไม่ถูกต้อง';
                      if (v.trim().toLowerCase() ==
                          AppProvider.defaultAdminEmail) {
                        return 'กรุณาใช้อีเมลอื่นที่ไม่ใช่ค่าเริ่มต้น';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  Text(
                    'รหัสผ่านใหม่',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'ตั้งรหัสผ่านใหม่อย่างน้อย 6 ตัวอักษร',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                      if (v.length < 6)
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      if (v == AppProvider.defaultAdminPassword) {
                        return 'กรุณาใช้รหัสผ่านอื่นที่ไม่ใช่ค่าเริ่มต้น';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  Text(
                    'ยืนยันรหัสผ่านใหม่',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'กรอกรหัสผ่านเดิมอีกครั้ง',
                      prefixIcon: const Icon(Icons.lock_clock_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passCtrl.text) return 'รหัสผ่านไม่ตรงกัน';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _onSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving
                            ? 'กำลังบันทึก...'
                            : 'บันทึกข้อมูลและเข้าสู่ระบบ',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
