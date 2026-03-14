// lib/screens/pin_setup_screen.dart
// Screen to set up a 6-digit PIN for quick access

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'admin_home_screen.dart';
import 'user_home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _error = '';

  void _onNumberTap(int num) {
    setState(() {
      _error = '';
      if (!_isConfirming) {
        if (_pin.length < 6) _pin += num.toString();
        if (_pin.length == 6) {
          _isConfirming = true;
        }
      } else {
        if (_confirmPin.length < 6) _confirmPin += num.toString();
        if (_confirmPin.length == 6) {
          _validateAndSave();
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      }
    });
  }

  void _validateAndSave() async {
    if (_pin == _confirmPin) {
      final provider = context.read<AppProvider>();
      await provider.savePin(_pin);
      
      if (!mounted) return;
      
      // Navigate to home after setting PIN
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => provider.isAdmin ? const AdminHomeScreen() : const UserHomeScreen(),
        ),
      );
    } else {
      setState(() {
        _confirmPin = '';
        _error = 'รหัส PIN ไม่ตรงกัน กรุณาลองใหม่';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.lock_person_rounded, size: 64, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              _isConfirming ? 'ยืนยันรหัส PIN 6 หลัก' : 'ตั้งรหัส PIN 6 หลัก',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming ? 'กรอกรหัสเดิมอีกครั้งเพื่อยืนยัน' : 'เพื่อความสะดวกในการเข้าใช้งานครั้งต่อไป',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool isActive = index < displayPin.length;
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
              
            const Spacer(),
            
            // Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
