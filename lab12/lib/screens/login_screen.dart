// lib/screens/login_screen.dart
// Login with Gmail + Password — Admin uses local credentials, Users use Sheet

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../services/sheets_service.dart';
import '../services/hash_service.dart';
import '../database/database_helper.dart';
import 'register_screen.dart';
import 'admin_home_screen.dart';
import 'user_home_screen.dart';
import 'pin_setup_screen.dart';
import 'force_update_admin_credentials_screen.dart';
import 'pending_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _error = '';

  @override
  void dispose() {
    _gmailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final appProvider = context.read<AppProvider>();
    final gmail = _gmailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    // ── 1. Check Admin credentials first (local check) ──────────────────────
    if (appProvider.checkAdminCredentials(gmail, password)) {
      appProvider.loginAsAdmin(gmail);
      if (!mounted) return;

      // ── Admin Security Check: Force update if using defaults ──────────
      if (appProvider.isUsingDefaultAdminCredentials) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ForceUpdateAdminCredentialsScreen(),
          ),
        );
        return;
      }

      // Admin also needs PIN setup if not exists
      if (!appProvider.hasPin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      }
      return;
    }

    // ── 2. Regular user: check Sheet (online) ────────────────────────────────
    final webAppUrl = appProvider.webAppUrl;
    UserModel? user;

    if (webAppUrl.isNotEmpty) {
      try {
        final sheetData = await SheetsService.instance.checkUser(
          webAppUrl,
          gmail,
        );
        if (sheetData != null) {
          user = UserModel(
            name: sheetData['Name']?.toString() ?? '',
            gmail: sheetData['Gmail']?.toString() ?? gmail,
            address: sheetData['Address']?.toString() ?? '',
            villageCode: sheetData['VillageCode']?.toString() ?? '',
            passwordHash: sheetData['PasswordHash']?.toString() ?? '',
            lat: double.tryParse(sheetData['Latitude']?.toString() ?? '0') ?? 0,
            lng:
                double.tryParse(sheetData['Longitude']?.toString() ?? '0') ?? 0,
            status: sheetData['Status']?.toString() ?? 'Pending',
          );
          // Upsert local DB (so hash is also stored locally)
          await DatabaseHelper.instance.insertUser(user);
        }
      } catch (_) {}
    }

    // ── 3. Fallback: check local SQLite ──────────────────────────────────────
    user ??= await DatabaseHelper.instance.getUserByGmail(gmail);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Not found → offer registration
    if (user == null) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegisterScreen(prefillGmail: gmail),
          ),
        );
      }
      return;
    }

    // ── 4. Verify password hash ───────────────────────────────
    if (user.passwordHash.isNotEmpty &&
        !HashService.verify(password, user.passwordHash)) {
      setState(() => _error = '❌ รหัสผ่านไม่ถูกต้อง');
      return;
    }

    // ── 5. Check user status ──────────────────────────────────────
    if (user.status == 'Pending') {
      // User is still pending approval
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            userName: user!.name,
            userGmail: user.gmail,
          ),
        ),
      );
      return;
    }

    // ── 6. Check if status is Rejected ────────────────────────────
    if (user.status == 'Rejected') {
      setState(() => _error = '❌ บัญชีของคุณถูกปฏิเสธ กรุณาติดต่อผู้ดูแลระบบ');
      return;
    }

    // ── 7. Login successful (status is Active) ───────────────────
    if (!mounted) return;
    appProvider.loginAs(user);

    // After login, check if user needs to set up a PIN
    if (!appProvider.hasPin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // App logo
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.handshake_rounded,
                      size: 52,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Community Tools',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'ระบบยืม-คืนอุปกรณ์ชุมชน',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                const SizedBox(height: 24),

                // Gmail
                Text('Gmail', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _gmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'example@gmail.com',
                    prefixIcon: const Icon(Icons.email_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณากรอก Gmail';
                    if (!v.contains('@')) return 'Gmail ไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                Text('รหัสผ่าน', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'รหัสผ่านที่ตั้งไว้ตอนสมัคร',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
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
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '* รหัสผ่านที่ตั้งไว้ตอนสมัครสมาชิก',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error,
                      style: TextStyle(color: cs.onErrorContainer),
                    ),
                  ),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _onLogin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(_isLoading ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ'),
                  ),
                ),
                const SizedBox(height: 16),

                // Register link
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
