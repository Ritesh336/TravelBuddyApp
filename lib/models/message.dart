import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String tripId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final List<String> readBy;

  Message({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    required this.readBy,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'readBy': readBy,
    };
  }
}