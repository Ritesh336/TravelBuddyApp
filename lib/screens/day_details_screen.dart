import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/trip_data.dart';
import '../models/trip.dart';
import 'add_activity_screen.dart';
import 'todo_list_screen.dart';
import 'expense_tracker_screen.dart';


class DayDetailsScreen extends StatefulWidget {
  final String tripId;
  final String dayId;

  const DayDetailsScreen({
    super.key,
    required this.tripId,
    required this.dayId,
  });

  @override
  _DayDetailsScreenState createState() => _DayDetailsScreenState();
}


class _DayDetailsScreenState extends State<DayDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripData>(
      builder: (context, tripData, child) {
        final trip = tripData.getTripById(widget.tripId);
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Day Details')),
            body: const Center(child: Text('Trip not found')),
          );
        }

        final day = trip.days.firstWhere(
          (d) => d.id == widget.dayId,
          orElse: () => throw Exception('Day not found'),
        );


        return Scaffold(
          appBar: AppBar(
            title: const Text('Day Details'),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
              tabs: const [
                Tab(
                  icon: Icon(Icons.event),
                  text: 'Activities',
                ),
                Tab(
                  icon: Icon(Icons.check_circle),
                  text: 'To-Do',
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Expenses',
                ),
              ],
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dateFormat.format(day.date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Activities Tab
                    _ActivitiesTab(tripId: widget.tripId, day: day),
                   
                    // To-Do Tab
                    TodoListScreen(tripId: widget.tripId),
                   
                    // Expenses Tab
                    ExpenseTrackerScreen(tripId: widget.tripId),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddActivityScreen(
                      tripId: widget.tripId,
                      dayId: widget.dayId,
                      initialDate: day.date,
                    ),
                  ),
                );
              } else if (_tabController.index == 1) {
                // Add To-Do item dialog
                _showAddTodoDialog(context, widget.tripId);
              } else {
                // Add Expense dialog
                _showAddExpenseDialog(context, widget.tripId, day.date);
              }
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                // Navigate to Home
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Trips',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTodoDialog(BuildContext context, String tripId) {
    final titleController = TextEditingController();


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add To-Do Item'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final todoItem = TodoItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                  );
                  Provider.of<TripData>(context, listen: false)
                      .addTodoItem(tripId, todoItem);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, String tripId, DateTime date) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Transportation';
    final categories = [
      'Transportation',
      'Accommodation',
      'Food',
      'Activities',
      'Shopping',
      'Other'
    ];


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          category = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty &&
                        amountController.text.trim().isNotEmpty) {
                      try {
                        final amount = double.parse(amountController.text.trim());
                        final expense = Expense(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          amount: amount,
                          date: date,
                          category: category,
                        );
                        Provider.of<TripData>(context, listen: false)
                            .addExpense(tripId, expense);
                        Navigator.pop(context);
                      } catch (e) {
                        // Show error for invalid number
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


class _ActivitiesTab extends StatelessWidget {
  final String tripId;
  final Day day;

  const _ActivitiesTab({
    required this.tripId,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return day.activities.isEmpty
        ? const Center(
            child: Text(
              'No activities yet. Tap the + button to add activities.',
              style: TextStyle(fontSize: 16),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: day.activities.length,
            itemBuilder: (context, index) {
              final activity = day.activities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${activity.startTime.format()} - ${activity.endTime.format()}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${activity.cost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.location,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
