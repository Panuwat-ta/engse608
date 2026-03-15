// lib/screens/user_profile_screen.dart
// Profile screen for regular users

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(AppProvider ap) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await ap.saveAdminProfileImage(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ap = context.watch<AppProvider>();
    final currentUser = ap.currentUser;

    // If no current user, go back
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            GestureDetector(
              onTap: () => _pickImage(ap),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                        image: ap.adminProfileImagePath.isNotEmpty
                            ? DecorationImage(
                                image: FileImage(
                                  File(ap.adminProfileImagePath),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: ap.adminProfileImagePath.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: cs.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentUser.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              currentUser.gmail,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Account Info Section
            _SectionHeader(
              title: 'ข้อมูลบัญชี',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.email_outlined,
              title: 'อีเมล',
              value: currentUser.gmail,
              onTap: () {
                Clipboard.setData(ClipboardData(text: currentUser.gmail));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ คัดลอกอีเมลแล้ว'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.home_work_outlined,
              title: 'รหัสหมู่บ้าน',
              value: currentUser.villageCode.isEmpty
                  ? 'ยังไม่ได้ตั้งค่า'
                  : currentUser.villageCode,
              onTap: () {
                if (currentUser.villageCode.isNotEmpty) {
                  Clipboard.setData(
                    ClipboardData(text: currentUser.villageCode),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ คัดลอกรหัสหมู่บ้านแล้ว'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.lock_outline_rounded,
              title: 'รหัสผ่าน',
              value: '●' * 8,
              onTap: () => _showChangePasswordDialog(context, ap),
            ),
            const SizedBox(height: 32),

            // Settings Section
            _SectionHeader(title: 'การตั้งค่า', icon: Icons.settings_outlined),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.notifications_outlined,
              title: 'การแจ้งเตือน',
              value: 'เปิดใช้งาน',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚧 ฟีเจอร์กำลังพัฒนา'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.language_rounded,
              title: 'ภาษา',
              value: 'ไทย',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚧 ฟีเจอร์กำลังพัฒนา'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.help_outline_rounded,
              title: 'ช่วยเหลือ',
              value: 'คู่มือการใช้งาน',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚧 ฟีเจอร์กำลังพัฒนา'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider ap) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('เปลี่ยนรหัสผ่าน'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              obscureText: obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'รหัสผ่านใหม่',
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setDialogState(() => obscure = !obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'กรุณากรอกรหัสผ่าน';
                if (v.length < 4) return 'รหัสผ่านสั้นเกินไป';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // For regular users, we can't change password here
                  // Password is managed through registration
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🚧 ติดต่อ Admin เพื่อเปลี่ยนรหัสผ่าน'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cs.primary,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
