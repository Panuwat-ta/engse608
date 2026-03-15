// lib/screens/manage_equipment_screen.dart
// Screen for managing equipment/tools

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_equipment_screen.dart';
import 'edit_equipment_screen.dart';

class ManageEquipmentScreen extends StatefulWidget {
  const ManageEquipmentScreen({super.key});

  @override
  State<ManageEquipmentScreen> createState() => _ManageEquipmentScreenState();
}

class _ManageEquipmentScreenState extends State<ManageEquipmentScreen> {
  List<Map<String, dynamic>> _equipment = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() => _loading = true);
    try {
      final equipment = await DatabaseHelper.instance.getAllEquipment();
      if (mounted) {
        setState(() {
          _equipment = equipment;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading equipment: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการอุปกรณ์'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEquipment,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _equipment.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีอุปกรณ์',
                    style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กดปุ่ม + เพื่อเพิ่มอุปกรณ์',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant.withAlpha(179),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _equipment.length,
              itemBuilder: (ctx, i) {
                final item = _equipment[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.build_rounded, color: cs.primary),
                    ),
                    title: Text(item['name'] ?? ''),
                    subtitle: Text(
                      '${item['category']} • ${item['description']}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['available']}/${item['quantity']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'ว่าง/ทั้งหมด',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditEquipmentScreen(equipment: item),
                        ),
                      );
                      _loadEquipment();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEquipmentScreen()));
          _loadEquipment();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มอุปกรณ์'),
      ),
    );
  }
}
