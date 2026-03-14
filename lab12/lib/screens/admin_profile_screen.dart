import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'pending_members_screen.dart';
import 'add_admin_screen.dart';
import 'manage_admins_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
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

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์และตั้งค่า'), centerTitle: true),
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
              'Admin: ${ap.adminEmail.split('@')[0]}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(ap.adminEmail, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),

            // Credentials Section
            _SectionHeader(
              title: 'ข้อมูลเข้าสู่ระบบ',
              icon: Icons.vpn_key_rounded,
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Admin Email',
              value: ap.adminEmail,
              onTap: () =>
                  _showEditDialog(context, 'Email', ap.adminEmail, (v) {
                    ap.saveAdminCredentials(
                      newEmail: v,
                      newPassword: ap.adminPassword,
                    );
                  }),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'รหัสผ่าน',
              value: '●' * ap.adminPassword.length,
              onTap: () => _showEditDialog(context, 'รหัสผ่าน', '', (v) {
                ap.saveAdminCredentials(
                  newEmail: ap.adminEmail,
                  newPassword: v,
                );
              }, isPassword: true),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.home_work_outlined,
              title: 'รหัสหมู่บ้าน',
              value: ap.adminVillageCode.isEmpty
                  ? 'ยังไม่ได้ตั้งค่า'
                  : ap.adminVillageCode,
              onTap: () => _showEditDialog(
                context,
                'รหัสหมู่บ้าน',
                ap.adminVillageCode,
                (v) {
                  ap.saveAdminCredentials(
                    newEmail: ap.adminEmail,
                    newPassword: ap.adminPassword,
                    newVillageCode: v,
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Management Section
            _SectionHeader(
              title: 'การจัดการระบบ',
              icon: Icons.admin_panel_settings_outlined,
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.group_add_outlined,
              title: 'จัดการผู้ดูแล (Admin)',
              value: 'เพิ่มหรือลบสิทธิ์ Admin ท่านอื่น',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageAdminsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.people_outline_rounded,
              title: 'จัดการสมาชิกทั่วไป',
              value: 'อนุมัติหรือปฏิเสธสมาชิกที่สมัครเข้ามา',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PendingMembersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.person_add_alt_rounded,
              title: 'เพิ่ม Admin ใหม่',
              value: 'เพิ่มผู้ดูแลระบบท่านใหม่',
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddAdminScreen()),
                );
                if (result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ เพิ่ม Admin สำเร็จแล้ว'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String label,
    String initialValue,
    Function(String) onSave, {
    bool isPassword = false,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    bool obscure = isPassword;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('แก้ไข $label'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              obscureText: obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'กรอก $label ใหม่',
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      )
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'กรุณากรอกข้อมูล';
                if (!isPassword && label == 'Email' && !v.contains('@')) {
                  return 'Email ไม่ถูกต้อง';
                }
                if (isPassword && v.length < 4) return 'รหัสผ่านสั้นเกินไป';
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
                  onSave(ctrl.text.trim());
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ อัปเดต $label สำเร็จ')),
                  );
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
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
                Icons.edit_rounded,
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
