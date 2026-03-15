// lib/screens/add_equipment_screen.dart
// Screen for adding new equipment

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final quantity = int.parse(_quantityController.text);

      await DatabaseHelper.instance.insertEquipment({
        'id': DateTime.now().millisecondsSinceEpoch,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'quantity': quantity,
        'available': quantity,
        'status': 'Active',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ เพิ่มอุปกรณ์สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มอุปกรณ์'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่ออุปกรณ์',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_rounded),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'กรุณากรอกชื่ออุปกรณ์' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 3,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'กรุณากรอกรายละเอียด' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_rounded),
                hintText: 'เช่น เครื่องมือช่าง, เครื่องใช้ไฟฟ้า',
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'กรุณากรอกหมวดหมู่' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'จำนวน',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'กรุณากรอกจำนวน';
                final num = int.tryParse(v!);
                if (num == null || num <= 0) return 'จำนวนต้องมากกว่า 0';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _saveEquipment,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึก'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}
