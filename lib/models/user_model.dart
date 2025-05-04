import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final List<String> interests;
  final List<String> preferredDestinations;
  final List<String> pastTrips;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.interests,
    required this.preferredDestinations,
    required this.pastTrips,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      preferredDestinations: List<String>.from(data['preferredDestinations'] ?? []),
      pastTrips: List<String>.from(data['pastTrips'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'interests': interests,
      'preferredDestinations': preferredDestinations,
      'pastTrips': pastTrips,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}