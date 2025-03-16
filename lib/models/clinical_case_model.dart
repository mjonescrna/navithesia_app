import 'package:navithesia_beta/constants/coa_constants.dart';
import 'package:navithesia_beta/models/coa_category_model.dart';

class ClinicalCase {
  final String id;
  final DateTime date;
  final String procedure;
  final int patientAge;
  final String patientGender;
  final String patientASA;
  final bool isEmergency;
  final List<String> anesthesiaTypes;
  final List<CoaCategory> categories;
  final double duration;
  final String notes;
  final List<String> uniqueCategories;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSimulated;

  ClinicalCase({
    required this.id,
    required this.date,
    required this.procedure,
    required this.patientAge,
    required this.patientGender,
    required this.patientASA,
    required this.isEmergency,
    required this.anesthesiaTypes,
    required this.categories,
    required this.duration,
    required this.notes,
    required this.uniqueCategories,
    this.isSimulated = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Helper method to get all applicable categories including parent categories
  List<String> get allCategoryIds {
    final Set<String> categoryIds = {...uniqueCategories};

    // Add parent categories for each selected category
    for (final categoryId in uniqueCategories) {
      final category = CoaConstants.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse:
            () => CoaCategory(
              id: categoryId,
              name: 'Unknown',
              requiredCount: 0,
              description: 'Unknown category',
              group: 'unknown',
              isRequired: false,
            ),
      );

      // Add parent category if it exists
      if (category.parentId != null) {
        categoryIds.add(category.parentId!);
      }
    }

    return categoryIds.toList();
  }

  // Helper method to get category names for display
  List<String> get categoryNames {
    return allCategoryIds.map((id) {
      final category = CoaConstants.categories.firstWhere(
        (c) => c.id == id,
        orElse: () => CoaConstants.categories.first,
      );
      return category.name;
    }).toList();
  }

  // Added getters for compatibility with existing code
  String get anesthesiaType =>
      anesthesiaTypes.isNotEmpty ? anesthesiaTypes.first : 'General';

  String get patientAgeCategory {
    if (patientAge < 1) return 'Neonate';
    if (patientAge < 2) return 'Pediatric (<2 years)';
    if (patientAge < 13) return 'Pediatric (2-12 years)';
    if (patientAge < 18) return 'Adolescent (13-17 years)';
    if (patientAge < 65) return 'Adult (18-64 years)';
    return 'Geriatric (65+ years)';
  }

  String get asaClass => patientASA;

  // Use duration as durationHours for compatibility
  double get durationHours => duration;

  // Return empty string for location (removed field)
  String get location => '';

  // Return uniqueCategories as coaCategories for compatibility
  List<String> get coaCategories => uniqueCategories;

  // Helper method to get categories by group
  Map<String, List<String>> get categoriesByGroup {
    final Map<String, List<String>> grouped = {};

    for (final categoryId in allCategoryIds) {
      final category = CoaConstants.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CoaConstants.categories.first,
      );

      if (!grouped.containsKey(category.group)) {
        grouped[category.group] = [];
      }
      grouped[category.group]!.add(categoryId);
    }

    return grouped;
  }

  // Create a ClinicalCase from JSON
  factory ClinicalCase.fromJson(Map<String, dynamic> json) {
    List<CoaCategory> categoriesList = [];

    if (json['categories'] != null) {
      List<dynamic> categoriesJson = json['categories'];
      categoriesList =
          categoriesJson
              .map(
                (categoryJson) =>
                    CoaCategory.fromJson(categoryJson as Map<String, dynamic>),
              )
              .toList();
    }

    return ClinicalCase(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      procedure: json['procedure'] as String,
      patientAge: json['patientAge'] as int,
      patientGender: json['patientGender'] as String,
      patientASA: json['patientASA'] as String,
      isEmergency: (json['isEmergency'] as bool?) ?? false,
      anesthesiaTypes: List<String>.from(
        json['anesthesiaTypes'] as List? ?? [],
      ),
      categories: categoriesList,
      duration: (json['duration'] as num).toDouble(),
      notes: (json['notes'] as String?) ?? '',
      uniqueCategories: List<String>.from(
        json['uniqueCategories'] as List? ?? [],
      ),
      isSimulated: (json['isSimulated'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'procedure': procedure,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientASA': patientASA,
      'isEmergency': isEmergency,
      'anesthesiaTypes': anesthesiaTypes,
      'categories': categories.map((category) => category.toJson()).toList(),
      'duration': duration,
      'notes': notes,
      'uniqueCategories': uniqueCategories,
      'isSimulated': isSimulated,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ClinicalCase copyWith({
    String? id,
    DateTime? date,
    String? procedure,
    int? patientAge,
    String? patientGender,
    String? patientASA,
    bool? isEmergency,
    List<String>? anesthesiaTypes,
    List<CoaCategory>? categories,
    double? duration,
    String? notes,
    List<String>? uniqueCategories,
    bool? isSimulated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalCase(
      id: id ?? this.id,
      date: date ?? this.date,
      procedure: procedure ?? this.procedure,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientASA: patientASA ?? this.patientASA,
      isEmergency: isEmergency ?? this.isEmergency,
      anesthesiaTypes: anesthesiaTypes ?? this.anesthesiaTypes,
      categories: categories ?? this.categories,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      uniqueCategories: uniqueCategories ?? this.uniqueCategories,
      isSimulated: isSimulated ?? this.isSimulated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
