import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserData() async {
    if (FirebaseService.userId == null) {
      _user = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(FirebaseService.userId)
          .get();

      if (doc.exists) {
        _user = UserModel.fromFirestore(doc);
      } else {
        _error = 'User data not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    List<String>? interests,
    List<String>? preferredDestinations,
  }) async {
    if (FirebaseService.userId == null || _user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (interests != null) updates['interests'] = interests;
      if (preferredDestinations != null) {
        updates['preferredDestinations'] = preferredDestinations;
      }

      await FirebaseService.firestore
          .collection('users')
          .doc(FirebaseService.userId)
          .update(updates);

      await loadUserData();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}