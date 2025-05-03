import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip_data.dart';


class TodoListScreen extends StatelessWidget {
  final String tripId;

  const TodoListScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripData>(
      builder: (context, tripData, child) {
        final trip = tripData.getTripById(tripId);
       
        if (trip == null) {
          return const Center(child: Text('Trip not found'));
        }

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Trip To-Do List',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: trip.todoList.isEmpty
                    ? const Center(
                        child: Text(
                          'No to-do items yet. Tap the + button to add items.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: trip.todoList.length,
                        itemBuilder: (context, index) {
                          final item = trip.todoList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: CheckboxListTile(
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  decoration: item.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.completed
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              value: item.completed,
                              onChanged: (value) {
                                Provider.of<TripData>(context, listen: false)
                                    .toggleTodoItem(tripId, item.id);
                              },
                              activeColor: Colors.blue,
                              checkColor: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
