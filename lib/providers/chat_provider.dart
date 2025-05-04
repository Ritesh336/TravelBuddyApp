import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentTripId;
  Stream<QuerySnapshot>? _messagesStream;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<QuerySnapshot>? get messagesStream => _messagesStream;

  // Initialize chat for a specific trip
  void initChat(String tripId) {
    _currentTripId = tripId;
    _messagesStream = FirebaseService.firestore
        .collection('messages')
        .where('tripId', isEqualTo: tripId)
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots();
    
    notifyListeners();
  }

  // Send a message
  Future<void> sendMessage(String content) async {
    if (FirebaseService.userId == null || _currentTripId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user's name
      final userDoc = await FirebaseService.firestore
          .collection('users')
          .doc(FirebaseService.userId)
          .get();
      
      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      
      // Create message
      final message = Message(
        id: '',
        tripId: _currentTripId!,
        senderId: FirebaseService.userId!,
        senderName: userName,
        content: content,
        sentAt: DateTime.now(),
        readBy: [FirebaseService.userId!],
      );
      
      // Add message to Firestore
      await FirebaseService.firestore
          .collection('messages')
          .add(message.toFirestore());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    if (FirebaseService.userId == null) return;
    
    try {
      final batch = FirebaseService.firestore.batch();
      
      for (final messageId in messageIds) {
        final messageRef = FirebaseService.firestore
            .collection('messages')
            .doc(messageId);
            
        final messageDoc = await messageRef.get();
        
        if (messageDoc.exists) {
          final message = Message.fromFirestore(messageDoc);
          
          if (!message.readBy.contains(FirebaseService.userId)) {
            final updatedReadBy = List<String>.from(message.readBy)
              ..add(FirebaseService.userId!);
              
            batch.update(messageRef, {'readBy': updatedReadBy});
          }
        }
      }
      
      await batch.commit();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear current chat
  void clearChat() {
    _messages = [];
    _currentTripId = null;
    _messagesStream = null;
    notifyListeners();
  }
}