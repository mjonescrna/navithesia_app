import 'package:intl/intl.dart';

/// Model representing a time entry (clock in/out) at a clinical site
class TimeEntry {
  final String id;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final String clinicalSiteId;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeEntry({
    required this.id,
    required this.clockInTime,
    this.clockOutTime,
    required this.clinicalSiteId,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  // Get duration in hours
  double get durationHours {
    if (clockOutTime == null) {
      // If still clocked in, calculate duration until now
      final now = DateTime.now();
      return now.difference(clockInTime).inMinutes / 60.0;
    } else {
      return clockOutTime!.difference(clockInTime).inMinutes / 60.0;
    }
  }

  // Check if the shift is currently active (not clocked out)
  bool get isActive => clockOutTime == null;

  // Format the duration as a string
  String get formattedDuration {
    final hours = durationHours;

    if (isActive) {
      // For active shifts, show "X hours (ongoing)"
      final hoursInt = hours.floor();
      final minutes = ((hours - hoursInt) * 60).round();

      if (hoursInt > 0) {
        return '$hoursInt hr${hoursInt != 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''} (ongoing)';
      } else {
        return '$minutes min (ongoing)';
      }
    } else {
      // For completed shifts
      final hoursInt = hours.floor();
      final minutes = ((hours - hoursInt) * 60).round();

      if (hoursInt > 0) {
        return '$hoursInt hr${hoursInt != 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
      } else {
        return '$minutes min';
      }
    }
  }

  // Format clock in time as a string
  String get formattedClockInTime => _formatTime(clockInTime);

  // Format clock out time as a string
  String get formattedClockOutTime {
    if (clockOutTime == null) return 'Active';
    return _formatTime(clockOutTime!);
  }

  // Helper method to format DateTime objects
  String _formatTime(DateTime time) {
    final formatter = DateFormat('MMM d, yyyy h:mm a');
    return formatter.format(time);
  }

  // Create a copy with some fields changed
  TimeEntry copyWith({
    String? id,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String? clinicalSiteId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      clinicalSiteId: clinicalSiteId ?? this.clinicalSiteId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Method to handle clocking out
  TimeEntry clockOut({DateTime? time, String? updatedNotes}) {
    return copyWith(
      clockOutTime: time ?? DateTime.now(),
      notes: updatedNotes,
      updatedAt: DateTime.now(),
    );
  }

  // Convert to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clockInTime': clockInTime.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'clinicalSiteId': clinicalSiteId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from a Map from storage
  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'] as String,
      clockInTime: DateTime.parse(map['clockInTime'] as String),
      clockOutTime:
          map['clockOutTime'] != null
              ? DateTime.parse(map['clockOutTime'] as String)
              : null,
      clinicalSiteId: map['clinicalSiteId'] as String,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'TimeEntry{id: $id, clockIn: $formattedClockInTime, clockOut: $formattedClockOutTime, duration: $formattedDuration}';
  }
}
