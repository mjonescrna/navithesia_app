import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';

class UserGoal {
  final String categoryId;
  final int targetCount;
  final DateTime createdAt;

  UserGoal({
    required this.categoryId,
    required this.targetCount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      categoryId: json['categoryId'] as String,
      targetCount: json['targetCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'targetCount': targetCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UserGoalsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<UserGoal> _userGoals = [];
  bool _isLoading = false;

  static const String _userGoalsKey = 'user_goals';
  static const int _maxUserGoals = 10;
  static const int _minUserGoals = 4;

  UserGoalsProvider(this._prefs) {
    _loadUserGoals();
  }

  List<UserGoal> get userGoals => _userGoals;
  bool get isLoading => _isLoading;
  int get maxUserGoals => _maxUserGoals;
  int get minUserGoals => _minUserGoals;

  // Load user goals from SharedPreferences
  Future<void> _loadUserGoals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? userGoalsJson = _prefs.getString(_userGoalsKey);
      if (userGoalsJson != null) {
        final List<dynamic> decoded = json.decode(userGoalsJson);
        _userGoals = decoded.map((item) => UserGoal.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading user goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save user goals to SharedPreferences
  Future<void> _saveUserGoals() async {
    try {
      final String encoded = json.encode(
        _userGoals.map((goal) => goal.toJson()).toList(),
      );
      await _prefs.setString(_userGoalsKey, encoded);
    } catch (e) {
      debugPrint('Error saving user goals: $e');
    }
  }

  // Add a new user goal
  Future<bool> addUserGoal(String categoryId, int targetCount) async {
    // Check if max goals reached
    if (_userGoals.length >= _maxUserGoals) {
      return false;
    }

    // Check if goal already exists
    if (_userGoals.any((goal) => goal.categoryId == categoryId)) {
      return await updateUserGoalTarget(categoryId, targetCount);
    }

    // Add new goal
    _userGoals.add(UserGoal(categoryId: categoryId, targetCount: targetCount));

    await _saveUserGoals();
    notifyListeners();
    return true;
  }

  // Update an existing user goal target
  Future<bool> updateUserGoalTarget(String categoryId, int targetCount) async {
    final index = _userGoals.indexWhere(
      (goal) => goal.categoryId == categoryId,
    );
    if (index == -1) {
      return false;
    }

    _userGoals[index] = UserGoal(
      categoryId: categoryId,
      targetCount: targetCount,
    );

    await _saveUserGoals();
    notifyListeners();
    return true;
  }

  // Remove a user goal
  Future<bool> removeUserGoal(String categoryId) async {
    // Don't allow removing if we're at minimum goals
    if (_userGoals.length <= _minUserGoals) {
      return false;
    }

    final initialLength = _userGoals.length;
    _userGoals.removeWhere((goal) => goal.categoryId == categoryId);

    if (_userGoals.length < initialLength) {
      await _saveUserGoals();
      notifyListeners();
      return true;
    }

    return false;
  }

  // Get user goal for a category
  UserGoal? getUserGoalForCategory(String categoryId) {
    try {
      return _userGoals.firstWhere((goal) => goal.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get all categories with user goals
  List<String> get userGoalCategoryIds =>
      _userGoals.map((goal) => goal.categoryId).toList();

  // Check if a category has a user goal
  bool hasUserGoal(String categoryId) {
    return _userGoals.any((goal) => goal.categoryId == categoryId);
  }

  // Clear all user goals
  Future<void> clearUserGoals() async {
    _userGoals = [];
    await _saveUserGoals();
    notifyListeners();
  }
}
