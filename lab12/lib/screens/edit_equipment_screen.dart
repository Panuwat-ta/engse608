// lib/screens/edit_equipment_screen.dart
// Screen for editing equipment

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';

class EditEquipmentScreen extends StatefulWidget {
  final Map<String, dynamic> equipment;

  const EditEquipmentScreen({super.key, required this.equipment});

  @override
  State<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends State<EditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _quantityController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment['name']);
    _descriptionController = TextEditingController(
      text: widget.equipment['description'],
    );
    _categoryController = TextEditingController(
      text: widget.equipment['category'],
    );
    _quantityController = TextEditingController(
      text: widget.equipment['quantity'].toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _updateEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final oldQuantity = widget.equipment['quantity'] as int;
      final oldAvailable = widget.equipment['available'] as int;
      final newQuantity = int.parse(_quantityController.text);
      final diff = newQuantity - oldQuantity;
      final newAvailable = oldAvailable + diff;

      if (newAvailable < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ จำนวนใหม่ต้องไม่น้อยกว่าจำนวนที่ถูกยืมไป'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _saving = false);
        return;
      }

      await DatabaseHelper.instance
          .updateEquipment(widget.equipment['id'] as int, {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _categoryController.text.trim(),
            'quantity': newQuantity,
            'available': newAvailable,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ อัปเดตอุปกรณ์สำเร็จ'),
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

  Future<void> _deleteEquipment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบ "${widget.equipment['name']}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DatabaseHelper.instance.deleteEquipment(
        widget.equipment['id'] as int,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ลบอุปกรณ์สำเร็จ'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantity = widget.equipment['quantity'] as int;
    final available = widget.equipment['available'] as int;
    final borrowed = quantity - available;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขอุปกรณ์'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _deleteEquipment,
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'ลบอุปกรณ์',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (borrowed > 0)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'มีการยืมอยู่ $borrowed ชิ้น',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (borrowed > 0) const SizedBox(height: 16),
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
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'กรุณากรอกหมวดหมู่' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'จำนวนทั้งหมด',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers_rounded),
                helperText: borrowed > 0 ? 'กำลังถูกยืม: $borrowed ชิ้น' : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'กรุณากรอกจำนวน';
                final num = int.tryParse(v!);
                if (num == null || num <= 0) return 'จำนวนต้องมากกว่า 0';
                if (num < borrowed) {
                  return 'จำนวนต้องไม่น้อยกว่าที่ถูกยืมไป ($borrowed)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _updateEquipment,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}
