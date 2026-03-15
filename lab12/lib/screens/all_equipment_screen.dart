// lib/screens/all_equipment_screen.dart
// Screen to display all equipment (including unavailable ones)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/app_provider.dart';
import '../services/sync_service.dart';

class AllEquipmentScreen extends StatefulWidget {
  const AllEquipmentScreen({super.key});

  @override
  State<AllEquipmentScreen> createState() => _AllEquipmentScreenState();
}

class _AllEquipmentScreenState extends State<AllEquipmentScreen> {
  List<Map<String, dynamic>> _equipment = [];
  List<String> _categories = [];
  String _selectedCategory = 'ทั้งหมด';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final equipment = await DatabaseHelper.instance.getAllEquipment();
      final categories = await DatabaseHelper.instance.getEquipmentCategories();

      setState(() {
        _equipment = equipment;
        _categories = ['ทั้งหมด', ...categories];
        _loading = false;
      });

      if (mounted) {
        final appProvider = context.read<AppProvider>();
        if (appProvider.webAppUrl.isNotEmpty) {
          SyncService.instance.manualSync(appProvider.webAppUrl).then((result) {
            if (mounted && result.success) {
              _reloadFromDatabase();
            }
          });
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reloadFromDatabase() async {
    try {
      final equipment = await DatabaseHelper.instance.getAllEquipment();
      final categories = await DatabaseHelper.instance.getEquipmentCategories();

      if (mounted) {
        setState(() {
          _equipment = equipment;
          _categories = ['ทั้งหมด', ...categories];
        });
      }
    } catch (e) {
      debugPrint('Error reloading equipment: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredEquipment {
    if (_selectedCategory == 'ทั้งหมด') {
      return _equipment;
    }
    return _equipment.where((e) => e['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('อุปกรณ์ที่มี'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_loading && _categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: cs.surfaceContainerHighest,
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : cs.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEquipment.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่มีอุปกรณ์',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredEquipment.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _filteredEquipment[index];
                        final available = item['available'] as int? ?? 0;
                        final quantity = item['quantity'] as int? ?? 0;
                        final isAvailable = available > 0;

                        return Card(
                          elevation: 0,
                          color: cs.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isAvailable
                                ? BorderSide.none
                                : BorderSide(color: Colors.red.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.green.withAlpha(25)
                                        : Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['category']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ว่าง: $available/$quantity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isAvailable ? 'ว่าง' : 'ไม่ว่าง',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
