// lib/screens/equipment_list_screen.dart
// Screen to display available equipment for users

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/app_provider.dart';
import '../services/sync_service.dart';
import 'borrow_equipment_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  List<Map<String, dynamic>> _equipment = [];
  List<String> _categories = [];
  String _selectedCategory = 'ทั้งหมด';
  String _searchQuery = '';
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Load from Local Database first (instant display)
      final equipment = await DatabaseHelper.instance.getAllEquipment();
      final categories = await DatabaseHelper.instance.getEquipmentCategories();

      setState(() {
        _equipment = equipment;
        _categories = ['ทั้งหมด', ...categories];
        _loading = false;
      });

      // Sync in background if URL is configured
      if (mounted) {
        final appProvider = context.read<AppProvider>();
        if (appProvider.webAppUrl.isNotEmpty) {
          SyncService.instance.manualSync(appProvider.webAppUrl).then((result) {
            if (mounted && result.success) {
              // Reload data after sync completes
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
      debugPrint('Error reloading equipment from database: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredEquipment {
    // Filter by category
    List<Map<String, dynamic>> filtered;
    if (_selectedCategory == 'ทั้งหมด') {
      filtered = _equipment;
    } else {
      filtered = _equipment
          .where((e) => e['category'] == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        final name = (e['name'] as String? ?? '').toLowerCase();
        final description = (e['description'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Filter only available equipment (available > 0)
    return filtered.where((e) {
      final available = e['available'] as int? ?? 0;
      return available > 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืมอุปกรณ์'),
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
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาอุปกรณ์...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category filter
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

          // Equipment list
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
                        return _EquipmentCard(equipment: item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> equipment;

  const _EquipmentCard({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = equipment['name']?.toString() ?? '-';
    final description = equipment['description']?.toString() ?? '';
    final category = equipment['category']?.toString() ?? '';
    final quantity = equipment['quantity'] as int? ?? 0;
    final available = equipment['available'] as int? ?? 0;
    final status = equipment['status']?.toString() ?? 'Available';

    final isAvailable = available > 0 && status == 'Available';

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAvailable
            ? BorderSide.none
            : BorderSide(color: Colors.red.shade300),
      ),
      child: InkWell(
        onTap: () {
          _showEquipmentDetails(context, equipment);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
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
                  _getCategoryIcon(category),
                  color: isAvailable ? Colors.green : Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ว่าง: $available/$quantity',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.red,
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
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'เครื่องมือสวน':
        return Icons.grass_rounded;
      case 'เครื่องมือช่าง':
        return Icons.construction_rounded;
      case 'เฟอร์นิเจอร์':
        return Icons.chair_rounded;
      case 'อุปกรณ์กลางแจ้ง':
        return Icons.outdoor_grill_rounded;
      case 'อิเล็กทรอนิกส์':
        return Icons.electrical_services_rounded;
      case 'เครื่องมือทั่วไป':
        return Icons.handyman_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  void _showEquipmentDetails(
    BuildContext context,
    Map<String, dynamic> equipment,
  ) {
    final cs = Theme.of(context).colorScheme;
    final name = equipment['name']?.toString() ?? '-';
    final description = equipment['description']?.toString() ?? '';
    final category = equipment['category']?.toString() ?? '';
    final quantity = equipment['quantity'] as int? ?? 0;
    final available = equipment['available'] as int? ?? 0;
    final isAvailable = available > 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    _getCategoryIcon(category),
                    color: isAvailable ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (description.isNotEmpty) ...[
              Text(
                'รายละเอียด',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    icon: Icons.inventory_2_outlined,
                    label: 'จำนวนทั้งหมด',
                    value: '$quantity ชิ้น',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'ว่าง',
                    value: '$available ชิ้น',
                    valueColor: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isAvailable
                    ? () async {
                        Navigator.pop(ctx); // Close popup first
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BorrowEquipmentScreen(equipment: equipment),
                          ),
                        );
                        // Popup stays closed after borrowing
                      }
                    : null,
                icon: const Icon(Icons.shopping_bag_rounded),
                label: Text(isAvailable ? 'ยืมอุปกรณ์นี้' : 'ไม่ว่าง'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isAvailable ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
