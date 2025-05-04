import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/buddy_request.dart';

class BuddyProvider extends ChangeNotifier {
  List<UserModel> _suggestedBuddies = [];
  List<BuddyRequest> _sentRequests = [];
  List<BuddyRequest> _receivedRequests = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get suggestedBuddies => _suggestedBuddies;
  List<BuddyRequest> get sentRequests => _sentRequests;
  List<BuddyRequest> get receivedRequests => _receivedRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Find potential travel buddies based on shared interests or destinations
  Future<void> findPotentialBuddies(List<String> interests, List<String> destinations) async {
    if (FirebaseService.userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUserId = FirebaseService.userId!;
      final matchedUsers = <UserModel>[];
      
      // First, try to find users with matching interests
      for (final interest in interests) {
        final snapshot = await FirebaseService.firestore
            .collection('users')
            .where('interests', arrayContains: interest)
            .limit(5)
            .get();
            
        for (final doc in snapshot.docs) {
          if (doc.id != currentUserId) {
            final user = UserModel.fromFirestore(doc);
            if (!matchedUsers.any((u) => u.id == user.id)) {
              matchedUsers.add(user);
            }
          }
        }
      }
      
      // Next, try to find users with matching destinations
      for (final destination in destinations) {
        final snapshot = await FirebaseService.firestore
            .collection('users')
            .where('preferredDestinations', arrayContains: destination)
            .limit(5)
            .get();
            
        for (final doc in snapshot.docs) {
          if (doc.id != currentUserId) {
            final user = UserModel.fromFirestore(doc);
            if (!matchedUsers.any((u) => u.id == user.id)) {
              matchedUsers.add(user);
            }
          }
        }
      }
      
      // Limit to 10 suggestions
      _suggestedBuddies = matchedUsers.take(10).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search users by email
  Future<UserModel?> searchUserByEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a buddy request
  Future<void> sendBuddyRequest({
    required String receiverId,
    required String tripId,
    required String message,
  }) async {
    if (FirebaseService.userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = BuddyRequest(
        id: '',
        senderId: FirebaseService.userId!,
        receiverId: receiverId,
        tripId: tripId,
        message: message,
        sentAt: DateTime.now(),
      );
      
      await FirebaseService.firestore
          .collection('buddyRequests')
          .add(request.toFirestore());
          
      await loadSentRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Respond to a buddy request
  Future<void> respondToBuddyRequest(String requestId, bool accept) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = accept 
          ? BuddyRequestStatus.accepted 
          : BuddyRequestStatus.declined;
          
      await FirebaseService.firestore
          .collection('buddyRequests')
          .doc(requestId)
          .update({'status': status.index});
          
      // If accepted, add the user to the trip's travel buddies
      if (accept) {
        final request = _receivedRequests.firstWhere((req) => req.id == requestId);
        
        // Add the receiver to the trip's travel buddies
        final tripRef = FirebaseService.firestore
            .collection('trips')
            .doc(request.tripId);
            
        final tripDoc = await tripRef.get();
        if (tripDoc.exists) {
          final currentBuddies = List<String>.from(tripDoc.data()?['travelBuddies'] ?? []);
          if (!currentBuddies.contains(request.receiverId)) {
            currentBuddies.add(request.receiverId);
            await tripRef.update({'travelBuddies': currentBuddies});
          }
        }
      }
      
      await loadReceivedRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load sent buddy requests
  Future<void> loadSentRequests() async {
    if (FirebaseService.userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('buddyRequests')
          .where('senderId', isEqualTo: FirebaseService.userId)
          .orderBy('sentAt', descending: true)
          .get();
          
      _sentRequests = snapshot.docs
          .map((doc) => BuddyRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load received buddy requests
  Future<void> loadReceivedRequests() async {
    if (FirebaseService.userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseService.firestore
          .collection('buddyRequests')
          .where('receiverId', isEqualTo: FirebaseService.userId)
          .orderBy('sentAt', descending: true)
          .get();
          
      _receivedRequests = snapshot.docs
          .map((doc) => BuddyRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}