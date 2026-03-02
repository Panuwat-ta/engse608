import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lab11/ui/state/event_provider.dart';
import 'package:lab11/ui/state/category_provider.dart';
import 'package:lab11/ui/widgets/event_card.dart';
import 'package:lab11/ui/screens/category_manage_screen.dart';
import 'package:lab11/ui/screens/event_form_screen.dart';
import 'package:lab11/ui/screens/event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<EventProvider>().loadEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    String? tempDateFilter = eventProvider.dateFilter;
    int? tempCategoryId = eventProvider.categoryIdFilter;
    String? tempStatus = eventProvider.statusFilter;
    String tempSortBy = eventProvider.sortBy;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter & Sort Events'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempDateFilter ?? '',
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All Dates')),
                        DropdownMenuItem(value: 'today', child: Text('Today')),
                        DropdownMenuItem(
                          value: 'week',
                          child: Text('This Week'),
                        ),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('This Month'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          tempDateFilter = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: tempCategoryId ?? -1,
                      items: [
                        const DropdownMenuItem(
                          value: -1,
                          child: Text('All Categories'),
                        ),
                        ...categoryProvider.categories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (val) {
                        setState(() {
                          tempCategoryId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Status Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempStatus ?? '',
                      items: const [
                        DropdownMenuItem(
                          value: '',
                          child: Text('All Statuses'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          tempStatus = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sort By',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: tempSortBy,
                      items: const [
                        DropdownMenuItem(
                          value: 'event_date ASC, start_time ASC',
                          child: Text('Earliest Date'),
                        ),
                        DropdownMenuItem(
                          value: 'event_date DESC, start_time DESC',
                          child: Text('Latest Date'),
                        ),
                        DropdownMenuItem(
                          value: 'updated_at DESC',
                          child: Text('Last Updated'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            tempSortBy = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    eventProvider.clearFilters();
                    _searchController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    eventProvider.setFilters(
                      dateFilter: tempDateFilter,
                      categoryIdFilter: tempCategoryId,
                      statusFilter: tempStatus,
                      sortBy: tempSortBy,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManageScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<EventProvider>().setFilters(searchQuery: '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                context.read<EventProvider>().setFilters(searchQuery: value);
              },
            ),
          ),
          Expanded(
            child: Consumer2<EventProvider, CategoryProvider>(
              builder: (context, eventProvider, categoryProvider, child) {
                if (eventProvider.isLoading || categoryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (eventProvider.events.isEmpty) {
                  return const Center(
                    child: Text('No events found. Add some!'),
                  );
                }

                return ListView.builder(
                  itemCount: eventProvider.events.length,
                  itemBuilder: (context, index) {
                    final event = eventProvider.events[index];
                    final category = categoryProvider.categories
                        .cast<dynamic>()
                        .firstWhere(
                          (c) => c.id == event.categoryId,
                          orElse: () => null,
                        );

                    return EventCard(
                      event: event,
                      category: category,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailScreen(event: event),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
