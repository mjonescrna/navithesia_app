import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class FirebaseService {
  // For web platform, we'll use mock data
  Future<List<User>> getMockUsers() async {
    // In a real app, this could come from a local database or other source
    try {
      final prefs = await SharedPreferences.getInstance();
      final mockUsersString = prefs.getString('mock_users');

      if (mockUsersString != null) {
        // Parse and return the stored mock users
        final List<dynamic> userList = await compute(
          _parseUsers,
          mockUsersString,
        );
        return userList.map((e) => e as User).toList();
      }
    } catch (e) {
      debugPrint('Error retrieving mock users: $e');
    }

    // Return empty list if none found
    return [];
  }

  // Helper method to parse user data in isolate
  static List<User> _parseUsers(String jsonString) {
    // This would parse the JSON string into a list of User objects
    // For now, we'll just return a placeholder
    return [];
  }

  // Save a mock user (for web platform)
  Future<void> saveMockUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingUsers = await getMockUsers();

      // Check if user already exists and update, or add new
      final index = existingUsers.indexWhere((u) => u.id == user.id);
      if (index >= 0) {
        existingUsers[index] = user;
      } else {
        existingUsers.add(user);
      }

      // Save the updated list
      // In a real implementation, you would serialize the list to JSON
      // and save it to prefs
    } catch (e) {
      debugPrint('Error saving mock user: $e');
    }
  }
}
