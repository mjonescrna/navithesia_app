import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Model representing a clinical site (hospital) where the user completes rotations
class ClinicalSite {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime startDate;
  final int durationWeeks;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClinicalSite({
    String? id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.startDate,
    this.durationWeeks = 12,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculate end date based on start date and duration
  DateTime get endDate {
    return startDate.add(Duration(days: durationWeeks * 7));
  }

  // Check if the site period is ending soon (within 1 week)
  bool get isEnding {
    final remainingDays = daysLeft;
    return isActive && remainingDays >= 0 && remainingDays <= 7;
  }

  // Calculate days left in the rotation
  int get daysLeft {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  // Calculate progress percentage through the rotation
  double get progressPercentage {
    final now = DateTime.now();
    final totalDays = endDate.difference(startDate).inDays;
    final daysElapsed = now.difference(startDate).inDays;

    if (totalDays <= 0) return 1.0;
    return (daysElapsed / totalDays).clamp(0.0, 1.0);
  }

  // Format the rotation period as a string
  String get formattedPeriod {
    final dateFormat = DateFormat('MMM d, yyyy');
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  }

  // Create a copy with some fields changed
  ClinicalSite copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? startDate,
    int? durationWeeks,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalSite(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      startDate: startDate ?? this.startDate,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate.toIso8601String(),
      'durationWeeks': durationWeeks,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from a Map from storage
  factory ClinicalSite.fromMap(Map<String, dynamic> map) {
    return ClinicalSite(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      startDate: DateTime.parse(map['startDate'] as String),
      durationWeeks: map['durationWeeks'] as int,
      isActive: map['isActive'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'ClinicalSite{id: $id, name: $name, period: $formattedPeriod, active: $isActive, daysLeft: $daysLeft}';
  }
}
