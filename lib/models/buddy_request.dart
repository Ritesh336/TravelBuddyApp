import 'package:cloud_firestore/cloud_firestore.dart';

enum BuddyRequestStatus {
  pending,
  accepted,
  declined,
}

class BuddyRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String tripId;
  final String message;
  final DateTime sentAt;
  BuddyRequestStatus status;

  BuddyRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.tripId,
    required this.message,
    required this.sentAt,
    this.status = BuddyRequestStatus.pending,
  });

  factory BuddyRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BuddyRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      tripId: data['tripId'] ?? '',
      message: data['message'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      status: BuddyRequestStatus.values[data['status'] ?? 0],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'tripId': tripId,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status.index,
    };
  }
}