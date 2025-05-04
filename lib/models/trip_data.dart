import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trip.dart';
import '../services/firebase_service.dart';

class TripData extends ChangeNotifier {
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;
 
  // Getter for active or upcoming trips
  List<Trip> get activeTrips => _trips.where((trip) => !trip.completed).toList();
 
  // Getter for completed trips
  List<Trip> get completedTrips => _trips.where((trip) => trip.completed).toList();

  // Getter for shared trips
  List<Trip> get sharedTrips => _trips.where((trip) => trip.isShared).toList();

  // Load trips from local storage (for offline support)
  Future<void> loadTripsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = prefs.getStringList('trips') ?? [];
   
    _trips = tripsJson.map((tripJson) => Trip.fromJson(json.decode(tripJson))).toList();
    notifyListeners();
  }

  // Save trips to local storage (for offline support)
  Future<void> saveTripsToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final tripsJson = _trips.map((trip) => json.encode(trip.toJson())).toList();
   
    await prefs.setStringList('trips', tripsJson);
  }

  // Load trips from Firebase
  Future<void> loadTrips() async {
    if (FirebaseService.userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Query trips where userId matches current user
      final userTripsSnapshot = await FirebaseService.firestore
          .collection('trips')
          .where('userId', isEqualTo: FirebaseService.userId)
          .get();
      
      // Query trips where the current user is included as a travel buddy
      final sharedTripsSnapshot = await FirebaseService.firestore
          .collection('trips')
          .where('travelBuddies', arrayContains: FirebaseService.userId)
          .get();
      
      final List<Trip> loadedTrips = [];
      
      // Add user's own trips
      for (var doc in userTripsSnapshot.docs) {
        loadedTrips.add(Trip.fromFirestore(doc));
      }
      
      // Add trips shared with the user
      for (var doc in sharedTripsSnapshot.docs) {
        // Avoid duplicates if user is both owner and buddy
        if (!loadedTrips.any((trip) => trip.id == doc.id)) {
          loadedTrips.add(Trip.fromFirestore(doc));
        }
      }
      
      _trips = loadedTrips;
      
      // Also save to local storage for offline access
      await saveTripsToLocal();
    } catch (e) {
      _error = e.toString();
      // Try to load from local storage if Firebase fails
      await loadTripsFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new trip
  Future<void> addTrip(Trip trip) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add trip to Firestore
      final docRef = await FirebaseService.firestore
          .collection('trips')
          .add(trip.toFirestore());
      
      // Get the new trip with the Firestore ID
      final newTrip = Trip(
        id: docRef.id,
        userId: trip.userId,
        name: trip.name,
        startDate: trip.startDate,
        endDate: trip.endDate,
        days: trip.days,
        todoList: trip.todoList,
        expenses: trip.expenses,
        destinations: trip.destinations,
        completed: trip.completed,
        isShared: trip.isShared,
        travelBuddies: trip.travelBuddies,
      );
      
      _trips.add(newTrip);
      await saveTripsToLocal();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing trip
  Future<void> updateTrip(Trip trip) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Update trip in Firestore
      await FirebaseService.firestore
          .collection('trips')
          .doc(trip.id)
          .update(trip.toFirestore());
      
      // Update trip in local list
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
        await saveTripsToLocal();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a trip
  Future<void> deleteTrip(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Delete trip from Firestore
      await FirebaseService.firestore
          .collection('trips')
          .doc(id)
          .delete();
      
      // Remove trip from local list
      _trips.removeWhere((trip) => trip.id == id);
      await saveTripsToLocal();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a trip by ID
  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }
 
  // Toggle trip completion status
  Future<void> toggleTripCompletion(String id) async {
    final trip = getTripById(id);
    if (trip != null) {
      trip.completed = !trip.completed;
      await updateTrip(trip);
    }
  }

  // Toggle trip sharing status
  Future<void> toggleTripSharing(String id) async {
    final trip = getTripById(id);
    if (trip != null) {
      trip.isShared = !trip.isShared;
      await updateTrip(trip);
    }
  }

  // Add a travel buddy to a trip
  Future<void> addTravelBuddy(String tripId, String buddyUserId) async {
    final trip = getTripById(tripId);
    if (trip != null && !trip.travelBuddies.contains(buddyUserId)) {
      trip.travelBuddies.add(buddyUserId);
      await updateTrip(trip);
    }
  }

  // Remove a travel buddy from a trip
  Future<void> removeTravelBuddy(String tripId, String buddyUserId) async {
    final trip = getTripById(tripId);
    if (trip != null && trip.travelBuddies.contains(buddyUserId)) {
      trip.travelBuddies.remove(buddyUserId);
      await updateTrip(trip);
    }
  }

  // Add activity to a trip day
Future<void> addDayActivity(String tripId, String dayId, Activity activity) async {
  final trip = getTripById(tripId);
  if (trip != null) {
    // Use a for loop instead of firstWhere to avoid null safety issues
    Day? matchingDay;
    for (var day in trip.days) {
      if (day.id == dayId) {
        matchingDay = day;
        break;
      }
    }
    
    if (matchingDay != null) {
      matchingDay.activities.add(activity);
      await updateTrip(trip);
    }
  }
}

// Toggle todo item completion
Future<void> toggleTodoItem(String tripId, String todoId) async {
  final trip = getTripById(tripId);
  if (trip != null) {
    // Use a for loop instead of firstWhere to avoid null safety issues
    TodoItem? matchingItem;
    for (var item in trip.todoList) {
      if (item.id == todoId) {
        matchingItem = item;
        break;
      }
    }
    
    if (matchingItem != null) {
      matchingItem.completed = !matchingItem.completed;
      await updateTrip(trip);
    }
  }
}

// Add todo item to a trip
Future<void> addTodoItem(String tripId, TodoItem item) async {
  final trip = getTripById(tripId);
  if (trip != null) {
    trip.todoList.add(item);
    await updateTrip(trip);
  }
}

// Add expense to a trip
Future<void> addExpense(String tripId, Expense expense) async {
  final trip = getTripById(tripId);
  if (trip != null) {
    trip.expenses.add(expense);
    await updateTrip(trip);
  }
}
}