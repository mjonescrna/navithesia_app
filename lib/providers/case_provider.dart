import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navithesia_beta/models/clinical_case_model.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/time_entry_provider.dart';
import 'package:navithesia_beta/constants/coa_constants.dart';

class CaseProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<ClinicalCase> _cases = [];
  bool _isLoading = false;

  CaseProvider(this._prefs) {
    _loadCasesFromPrefs();
  }

  List<ClinicalCase> get cases => _cases;
  bool get isLoading => _isLoading;

  // Load cases from SharedPreferences
  Future<void> _loadCasesFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final casesJson = _prefs.getString(AppConstants.casesKey);
      if (casesJson != null) {
        final List<dynamic> decodedCases = json.decode(casesJson);
        _cases =
            decodedCases
                .map((caseJson) => ClinicalCase.fromJson(caseJson))
                .toList();
      }
    } catch (e) {
      debugPrint('Error loading cases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save cases to SharedPreferences
  Future<void> _saveCasesToPrefs() async {
    await _prefs.setString(
      AppConstants.casesKey,
      json.encode(_cases.map((c) => c.toJson()).toList()),
    );
  }

  // Add a new clinical case
  Future<bool> addCase(ClinicalCase clinicalCase) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Debug the categories that were added
      debugPrint(
        'ADDING CASE: Case categories to be added: ${clinicalCase.uniqueCategories.join(', ')}',
      );

      // Verify categories structure before adding
      if (clinicalCase.uniqueCategories.isEmpty) {
        debugPrint('WARNING: Case being added has NO categories!');
      }

      _cases.add(clinicalCase);
      await _saveCasesToPrefs();

      // Debug the state after adding
      debugPrint('ADDING CASE: Total cases after adding: ${_cases.length}');

      // Check category counts after adding
      for (final categoryId in clinicalCase.uniqueCategories) {
        try {
          final count = getCaseCountByCategory(categoryId);
          debugPrint(
            'ADDING CASE: After adding, count for $categoryId is $count',
          );
        } catch (e) {
          debugPrint('ADDING CASE: Error getting count for $categoryId: $e');
        }
      }

      // Force rebuild of UI by explicitly notifying listeners
      ensureGoalsUpdate();

      // Additional notification to ensure UI updates
      Future.delayed(const Duration(milliseconds: 100), () {
        notifyListeners();
      });

      return true;
    } catch (e) {
      debugPrint('Error adding case: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing clinical case
  Future<bool> updateCase(ClinicalCase updatedCase) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _cases.indexWhere((c) => c.id == updatedCase.id);
      if (index != -1) {
        _cases[index] = updatedCase;
        await _saveCasesToPrefs();

        // Debug the categories that were updated
        debugPrint(
          'Updated case with categories: ${updatedCase.uniqueCategories.join(', ')}',
        );

        // Call additional method to ensure goals update
        ensureGoalsUpdate();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating case: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a clinical case
  Future<bool> deleteCase(String caseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _cases.indexWhere((c) => c.id == caseId);
      if (index != -1) {
        // Debug the categories that will be removed
        debugPrint(
          'Deleting case with categories: ${_cases[index].uniqueCategories.join(', ')}',
        );

        _cases.removeAt(index);
        await _saveCasesToPrefs();

        // Call additional method to ensure goals update
        ensureGoalsUpdate();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting case: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a case by ID
  ClinicalCase? getCaseById(String caseId) {
    try {
      return _cases.firstWhere((c) => c.id == caseId);
    } catch (e) {
      return null;
    }
  }

  // Get cases by COA category
  List<ClinicalCase> getCasesByCategory(String categoryId) {
    try {
      final category = CoaConstants.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse:
            () => CoaCategory(
              id: categoryId,
              name: 'Unknown Category',
              requiredCount: 0,
              description: 'Unknown category',
              group: 'unknown',
              isRequired: false,
            ),
      );
      final allApplicableIds = _getAllApplicableCategoryIds(category);

      return _cases
          .where(
            (c) => c.coaCategories.any(
              (catId) => allApplicableIds.contains(catId),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting cases for category $categoryId: $e');
      return [];
    }
  }

  // Get case count for a specific category, including both actual and simulated cases
  int getCaseCountByCategory(String categoryId) {
    // Find all cases that include this category
    final matchingCases =
        cases
            .where((caseItem) => caseItem.uniqueCategories.contains(categoryId))
            .toList();

    return matchingCases.length;
  }

  // Get separate counts for actual and simulated cases for a category
  Map<String, int> getDetailedCaseCountByCategory(String categoryId) {
    final actualCases =
        cases
            .where(
              (caseItem) =>
                  caseItem.uniqueCategories.contains(categoryId) &&
                  !caseItem.isSimulated,
            )
            .length;

    final simulatedCases =
        cases
            .where(
              (caseItem) =>
                  caseItem.uniqueCategories.contains(categoryId) &&
                  caseItem.isSimulated,
            )
            .length;

    return {
      'actual': actualCases,
      'simulated': simulatedCases,
      'total': actualCases + simulatedCases,
    };
  }

  // Get cases by category group
  List<ClinicalCase> getCasesByCategoryGroup(String groupId) {
    try {
      final groupCategories =
          CoaConstants.categories
              .where((c) => c.group == groupId)
              .map((c) => c.id)
              .toList();

      return _cases
          .where(
            (c) =>
                c.coaCategories.any((catId) => groupCategories.contains(catId)),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting cases for group $groupId: $e');
      return [];
    }
  }

  // Get count of cases by category group
  int getCaseCountByCategoryGroup(String groupId) {
    try {
      final groupCategories =
          CoaConstants.categories
              .where((c) => c.group == groupId)
              .map((c) => c.id)
              .toList();

      return _cases
          .where(
            (c) =>
                c.coaCategories.any((catId) => groupCategories.contains(catId)),
          )
          .length;
    } catch (e) {
      debugPrint('Error getting case count for group $groupId: $e');
      return 0;
    }
  }

  // Get progress towards required count for a category
  double getProgressForCategory(String categoryId) {
    final category = CoaConstants.categories.firstWhere(
      (c) => c.id == categoryId,
    );
    if (category.requiredCount == 0) {
      return 1.0; // No requirement means 100% progress
    }

    final count = getCaseCountByCategory(categoryId);
    return count / category.requiredCount;
  }

  // Get all categories that need more cases to meet requirements
  List<String> getCategoriesNeedingProgress() {
    return CoaConstants.categories
        .where((c) => c.isRequired && getProgressForCategory(c.id) < 1.0)
        .map((c) => c.id)
        .toList();
  }

  // Private helper method to get all applicable category IDs
  Set<String> _getAllApplicableCategoryIds(CoaCategory category) {
    final Set<String> ids = {category.id};

    // Add subcategory IDs if any
    if (category.subcategoryIds.isNotEmpty) {
      ids.addAll(category.subcategoryIds);
    }

    // If this is a subcategory, add the parent category ID
    if (category.parentId != null) {
      ids.add(category.parentId!);
    }

    return ids;
  }

  // Get total clinical hours
  double getTotalClinicalHours() {
    return _cases.fold(0.0, (sum, c) => sum + c.durationHours);
  }

  /// Get total clinical hours from time entries only (clock in/out)
  ///
  /// According to COA guidelines, "Clinical hours include time spent in the actual
  /// administration of anesthesia (i.e., anesthesia time) and other time spent in
  /// the clinical area." This represents all time tracked via clock in/out.
  double getTotalClinicalHoursWithTimeEntries(
    TimeEntryProvider timeEntryProvider,
  ) {
    // Only count hours from time entries, not cases
    // This prevents double-counting time
    return timeEntryProvider.getTotalHours();
  }

  /// Get total anesthesia time from cases only
  ///
  /// According to COA guidelines, this represents only the time spent in "actual
  /// administration of anesthesia." This is a subset of total clinical hours.
  double getTotalAnesthesiaHours() {
    // Calculate total hours from all cases (anesthesia time)
    return _cases.fold(0.0, (sum, c) => sum + c.durationHours);
  }

  // Get cases filtered by date range
  List<ClinicalCase> getCasesByDateRange(DateTime start, DateTime end) {
    return _cases
        .where((c) => c.date.isAfter(start) && c.date.isBefore(end))
        .toList();
  }

  // Get cases filtered by location
  List<ClinicalCase> getCasesByLocation(String location) {
    // Since location is no longer a field, this can only match if we're looking for empty locations
    if (location.isEmpty) {
      return _cases.toList();
    }
    return [];
  }

  // Get unique locations from all cases
  List<String> getUniqueLocations() {
    // Since location is no longer a field, return an empty list or a list with a default location
    return [''];
  }

  // Get cases filtered by anesthesia type
  List<ClinicalCase> getCasesByAnesthesiaType(String anesthesiaType) {
    return _cases
        .where((c) => c.anesthesiaTypes.contains(anesthesiaType))
        .toList();
  }

  // Get unique anesthesia types from all cases
  List<String> getUniqueAnesthesiaTypes() {
    Set<String> types = {};
    for (var c in _cases) {
      types.addAll(c.anesthesiaTypes);
    }
    return types.toList();
  }

  // Ensure goals are updated whenever cases change
  void ensureGoalsUpdate() {
    // Debug message to confirm it's being called
    debugPrint('CaseProvider ensuring goals update');

    // Force immediate update
    notifyListeners();

    // Add a delayed update to ensure changes propagate throughout the widget tree
    Future.delayed(const Duration(milliseconds: 300), () {
      debugPrint('CaseProvider delayed notification for goals update');
      notifyListeners();
    });
  }
}
