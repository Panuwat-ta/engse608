import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lab11/data/models/category.dart';
import 'package:lab11/ui/state/category_provider.dart';
import 'package:lab11/ui/widgets/category_badge.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  void _showAddEditDialog(BuildContext context, [Category? category]) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedHex = category?.colorHex ?? '#2196F3';
    String selectedIcon = category?.iconKey ?? 'label';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(category == null ? 'Add Category' : 'Edit Category'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Color',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Simple color selector
                      Wrap(
                        spacing: 8,
                        children:
                            [
                              '#F44336',
                              '#E91E63',
                              '#9C27B0',
                              '#673AB7',
                              '#3F51B5',
                              '#2196F3',
                              '#03A9F4',
                              '#00BCD4',
                              '#009688',
                              '#4CAF50',
                              '#8BC34A',
                              '#CDDC39',
                              '#FFEB3B',
                              '#FFC107',
                              '#FF9800',
                              '#FF5722',
                              '#795548',
                              '#9E9E9E',
                              '#607D8B',
                            ].map((hex) {
                              Color c = Color(
                                int.parse(
                                  "FF${hex.replaceAll('#', '')}",
                                  radix: 16,
                                ),
                              );
                              return GestureDetector(
                                onTap: () => setState(() => selectedHex = hex),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: selectedHex == hex
                                        ? Border.all(
                                            color: Colors.black,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Icon',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selectedIcon,
                        items:
                            [
                              'label',
                              'work',
                              'person',
                              'groups',
                              'home',
                              'shopping_cart',
                              'fitness_center',
                              'favorite',
                              'school',
                              'book',
                              'computer',
                              'attach_money',
                              'flight',
                            ].map((icon) {
                              return DropdownMenuItem(
                                value: icon,
                                child: Text(icon),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedIcon = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final provider = context.read<CategoryProvider>();

                      final newCategory = Category(
                        id: category?.id,
                        name: nameController.text.trim(),
                        colorHex: selectedHex,
                        iconKey: selectedIcon,
                      );

                      if (category == null) {
                        await provider.addCategory(newCategory);
                      } else {
                        await provider.updateCategory(newCategory);
                      }

                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final provider = context.read<CategoryProvider>();
                await provider.deleteCategory(category.id!);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot delete category in use!'),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return ListTile(
                title: Text(category.name),
                leading: CategoryBadge(
                  name: category.name,
                  colorHex: category.colorHex,
                  iconKey: category.iconKey,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddEditDialog(context, category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
