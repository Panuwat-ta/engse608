// lib/screens/pin_auth_screen.dart
// Authentication screen using 6-digit PIN

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/sheets_service.dart';
import '../database/database_helper.dart';
import 'admin_home_screen.dart';
import 'user_home_screen.dart';
import 'login_screen.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  String _pin = '';
  String _error = '';
  bool _isLoading = false;

  void _onNumberTap(int num) {
    if (_isLoading) return;
    setState(() {
      _error = '';
      if (_pin.length < 6) {
        _pin += num.toString();
      }
      if (_pin.length == 6) {
        _verifyPin();
      }
    });
  }

  void _onBackspace() {
    if (_isLoading) return;
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final ap = context.read<AppProvider>();
    if (ap.verifyPin(_pin)) {
      setState(() => _isLoading = true);
      
      try {
        // PIN correct! Now we need to restore the full session (UserModel)
        // based on lastLoggedInGmail.
        final gmail = ap.lastLoggedInGmail;
        
        // 1. Check if it's admin
        if (ap.checkAdminCredentials(gmail, ap.adminPassword)) {
          ap.loginAsAdmin(gmail);
        } else {
          // 2. Check local DB for regular user
          final localUser = await DatabaseHelper.instance.getUserByGmail(gmail);
          if (localUser != null) {
            ap.loginAs(localUser);
            
            // Try background sync with Sheet to update status etc.
            if (ap.webAppUrl.isNotEmpty) {
               SheetsService.instance.checkUser(ap.webAppUrl, gmail).then((data) {
                 if (data != null) {
                   ap.updateCurrentUserStatus(data['Status']?.toString() ?? 'Pending');
                 }
               }).catchError((_){});
            }
          } else {
            // This shouldn't happen if they had a PIN, but fallback to Login
            _goToLogin();
            return;
          }
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ap.isAdmin ? const AdminHomeScreen() : const UserHomeScreen(),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
          _pin = '';
        });
      }
    } else {
      setState(() {
        _pin = '';
        _error = 'รหัส PIN ไม่ถูกต้อง';
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ap = context.watch<AppProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.lock_outline_rounded, size: 60, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              'เข้าสู่ระบบด้วย PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              ap.lastLoggedInGmail,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool isActive = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? cs.primary : cs.surfaceContainerHighest,
                    border: Border.all(color: cs.primary.withAlpha(50)),
                  ),
                );
              }),
            ),
            
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_error, style: TextStyle(color: cs.error)),
              ),

            if (_isLoading)
               const Padding(
                 padding: EdgeInsets.only(top: 20),
                 child: CircularProgressIndicator(),
               ),
              
            const Spacer(),
            
            // Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  for (var row in [[1, 2, 3], [4, 5, 6], [7, 8, 9]])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((n) => _KeyButton(
                          label: n.toString(),
                          onTap: () => _onNumberTap(n),
                        )).toList(),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 70), // Empty space
                      _KeyButton(label: '0', onTap: () => _onNumberTap(0)),
                      _KeyButton(
                        icon: Icons.backspace_rounded,
                        onTap: _onBackspace,
                        isSecondary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            TextButton(
              onPressed: _goToLogin,
              child: const Text('เข้าสู่ระบบด้วย Gmail อื่น'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isSecondary;

  const _KeyButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSecondary ? Colors.transparent : cs.surfaceContainerLow,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: cs.primary)
              : Text(
                  label!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
        ),
      ),
    );
  }
}
