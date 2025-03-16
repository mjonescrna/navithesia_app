import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navithesia_beta/models/time_entry_model.dart';

class TimeEntryProvider with ChangeNotifier {
  List<TimeEntry> _entries = [];
  TimeEntry? _activeEntry;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final SharedPreferences _prefs;

  // Getters
  List<TimeEntry> get entries => _entries;
  TimeEntry? get activeEntry => _activeEntry;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get hasActiveEntry => _activeEntry != null;

  // Constructor
  TimeEntryProvider(this._prefs) {
    loadEntries();
  }

  // Load entries from storage
  Future<void> loadEntries() async {
    _setLoading(true);
    try {
      final entriesJson = _prefs.getString('time_entries');

      if (entriesJson != null) {
        final List<dynamic> decodedEntries = json.decode(entriesJson);
        _entries =
            decodedEntries
                .map(
                  (entryMap) =>
                      TimeEntry.fromMap(Map<String, dynamic>.from(entryMap)),
                )
                .toList();

        // Find active time entry (one without a clock out time)
        final activeEntries =
            _entries.where((entry) => entry.clockOutTime == null).toList();
        if (activeEntries.isNotEmpty) {
          _activeEntry = activeEntries.first;
        } else {
          _activeEntry = null;
        }
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load time entries: $e');
    }
  }

  // Save entries to storage
  Future<void> _saveEntries() async {
    try {
      final entriesJson = json.encode(
        _entries.map((entry) => entry.toMap()).toList(),
      );
      await _prefs.setString('time_entries', entriesJson);
    } catch (e) {
      _setError('Failed to save time entries: $e');
    }
  }

  // Clock in - create a new time entry
  Future<void> clockIn(String clinicalSiteId, {DateTime? clockInTime}) async {
    if (_activeEntry != null) {
      _setError('You already have an active shift. Please clock out first.');
      return;
    }

    _setLoading(true);
    try {
      final newEntry = TimeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clockInTime: clockInTime ?? DateTime.now(),
        clockOutTime: null,
        clinicalSiteId: clinicalSiteId,
        notes: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _entries.add(newEntry);
      _activeEntry = newEntry;

      await _saveEntries();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to clock in: $e');
    }
  }

  // Clock out from the current active time entry
  Future<void> clockOut({String notes = '', DateTime? clockOutTime}) async {
    if (_activeEntry == null) {
      _setError('No active shift found to clock out from.');
      return;
    }

    _setLoading(true);
    try {
      final index = _entries.indexWhere(
        (entry) => entry.id == _activeEntry!.id,
      );
      if (index >= 0) {
        // Update the entry with clock out time and notes
        final updatedEntry = _activeEntry!.copyWith(
          clockOutTime: clockOutTime ?? DateTime.now(),
          notes: notes.isNotEmpty ? notes : _activeEntry!.notes,
          updatedAt: DateTime.now(),
        );

        _entries[index] = updatedEntry;
        _activeEntry = null;

        await _saveEntries();
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Active time entry not found');
      }
    } catch (e) {
      _setError('Failed to clock out: $e');
    }
  }

  // Get entries for a specific clinical site
  List<TimeEntry> getEntriesForClinicalSite(String clinicalSiteId) {
    return _entries
        .where((entry) => entry.clinicalSiteId == clinicalSiteId)
        .toList()
      ..sort(
        (a, b) => b.clockInTime.compareTo(a.clockInTime),
      ); // Sort newest first
  }

  // Get entries within a date range
  List<TimeEntry> getEntriesInRange(DateTime startDate, DateTime endDate) {
    return _entries.where((entry) {
        return (entry.clockInTime.isAfter(startDate) ||
                entry.clockInTime.isAtSameMomentAs(startDate)) &&
            (entry.clockInTime.isBefore(endDate) ||
                entry.clockInTime.isAtSameMomentAs(endDate));
      }).toList()
      ..sort(
        (a, b) => b.clockInTime.compareTo(a.clockInTime),
      ); // Sort newest first
  }

  // Calculate total hours for a specific clinical site
  double getTotalHoursForClinicalSite(String clinicalSiteId) {
    final siteEntries = getEntriesForClinicalSite(clinicalSiteId);
    return siteEntries.fold(0.0, (total, entry) => total + entry.durationHours);
  }

  // Calculate total hours in a date range
  double getTotalHoursInRange(DateTime startDate, DateTime endDate) {
    final rangeEntries = getEntriesInRange(startDate, endDate);
    return rangeEntries.fold(
      0.0,
      (total, entry) => total + entry.durationHours,
    );
  }

  // Calculate total hours from all completed time entries
  double getTotalHours() {
    return _entries
        .where((entry) => entry.clockOutTime != null)
        .fold(0.0, (total, entry) => total + entry.durationHours);
  }

  // Update an existing time entry
  Future<void> updateTimeEntry({
    required String id,
    required DateTime clockInTime,
    DateTime? clockOutTime,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      // Find the entry by ID
      final index = _entries.indexWhere((entry) => entry.id == id);

      if (index == -1) {
        _setError('Time entry not found');
        return;
      }

      final existing = _entries[index];

      // Create updated entry
      final updatedEntry = existing.copyWith(
        clockInTime: clockInTime,
        clockOutTime: clockOutTime,
        notes: notes ?? existing.notes,
        updatedAt: DateTime.now(),
      );

      // Update in list
      _entries[index] = updatedEntry;

      // If this is the active entry, update _activeEntry reference
      if (existing.isActive) {
        if (clockOutTime == null) {
          // Still active, update reference
          _activeEntry = updatedEntry;
        } else {
          // No longer active
          _activeEntry = null;
        }
      } else if (clockOutTime == null && _activeEntry == null) {
        // Entry is now active and no other active entry exists
        _activeEntry = updatedEntry;
      } else if (clockOutTime == null &&
          _activeEntry != null &&
          _activeEntry!.id != id) {
        // Can't have two active entries
        _setError(
          'Cannot make this entry active while another shift is in progress',
        );
        return;
      }

      await _saveEntries();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update time entry: $e');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _hasError = false;
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    debugPrint('TimeEntryProvider Error: $message');
    notifyListeners();
  }
}
