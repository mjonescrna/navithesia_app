class CoaCategory {
  final String id;
  final String name;
  final int requiredCount;
  final int? recommendedCount;
  final String description;
  final List<String> keywords;
  final bool isSelected; // For dashboard selection
  final bool isRequired;
  final String? parentId;
  final List<String> subcategoryIds;
  final String helpText;
  final String group;
  final bool
  isGroup; // Indicates if this is a grouping category (not selectable directly)
  final bool
  isSimulated; // Indicates if this is a simulated rather than actual procedure

  const CoaCategory({
    required this.id,
    required this.name,
    required this.requiredCount,
    this.recommendedCount,
    required this.description,
    this.keywords = const [],
    this.isSelected = false,
    required this.isRequired,
    this.parentId,
    this.subcategoryIds = const [],
    this.helpText = '',
    required this.group,
    this.isGroup = false,
    this.isSimulated = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoaCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Create a CoaCategory from JSON
  factory CoaCategory.fromJson(Map<String, dynamic> json) {
    return CoaCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      requiredCount: json['required_count'] as int,
      recommendedCount: json['recommended_count'] as int?,
      description: json['description'] as String,
      keywords:
          json['keywords'] != null
              ? List<String>.from(json['keywords'] as List)
              : [],
      isSelected: json['isSelected'] as bool? ?? false,
      isRequired: json['isRequired'] as bool? ?? true,
      parentId: json['parentId'] as String?,
      subcategoryIds:
          json['subcategoryIds'] != null
              ? List<String>.from(json['subcategoryIds'] as List)
              : [],
      helpText: json['helpText'] as String? ?? '',
      group: json['group'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      isSimulated: json['isSimulated'] as bool? ?? false,
    );
  }

  // Convert a CoaCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'required_count': requiredCount,
      'recommended_count': recommendedCount,
      'description': description,
      'keywords': keywords,
      'isSelected': isSelected,
      'isRequired': isRequired,
      'parentId': parentId,
      'subcategoryIds': subcategoryIds,
      'helpText': helpText,
      'group': group,
      'isGroup': isGroup,
      'isSimulated': isSimulated,
    };
  }

  // Create a copy of CoaCategory with updated fields
  CoaCategory copyWith({
    String? id,
    String? name,
    int? requiredCount,
    int? recommendedCount,
    String? description,
    List<String>? keywords,
    bool? isSelected,
    bool? isRequired,
    String? parentId,
    List<String>? subcategoryIds,
    String? helpText,
    String? group,
    bool? isGroup,
    bool? isSimulated,
  }) {
    return CoaCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      requiredCount: requiredCount ?? this.requiredCount,
      recommendedCount: recommendedCount ?? this.recommendedCount,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      isSelected: isSelected ?? this.isSelected,
      isRequired: isRequired ?? this.isRequired,
      parentId: parentId ?? this.parentId,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      helpText: helpText ?? this.helpText,
      group: group ?? this.group,
      isGroup: isGroup ?? this.isGroup,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }

  // Helper method to check if this category has subcategories
  bool get hasSubcategories => subcategoryIds.isNotEmpty;

  // Helper method to check if this category is a subcategory
  bool get isSubcategory => parentId != null;
}

class CoaCategoryProgress {
  final CoaCategory category;
  final int currentCount;
  final int actualCount;
  final int simulatedCount;
  final double progressPercentage;

  CoaCategoryProgress({
    required this.category,
    required this.currentCount,
    this.actualCount = 0,
    this.simulatedCount = 0,
  }) : progressPercentage =
           category.requiredCount > 0
               ? (currentCount / category.requiredCount).clamp(0.0, 1.0)
               : 0.0;

  // Factory constructor to create from detailed counts
  factory CoaCategoryProgress.fromDetailedCounts({
    required CoaCategory category,
    required Map<String, int> detailedCounts,
  }) {
    final actualCount = detailedCounts['actual'] ?? 0;
    final simulatedCount = detailedCounts['simulated'] ?? 0;
    final totalCount =
        detailedCounts['total'] ?? (actualCount + simulatedCount);

    return CoaCategoryProgress(
      category: category,
      currentCount: totalCount,
      actualCount: actualCount,
      simulatedCount: simulatedCount,
    );
  }

  // Helper method to get the appropriate color based on progress
  int getColorCode() {
    if (progressPercentage >= 0.91) {
      return 3; // Green - Complete or nearly complete
    } else if (progressPercentage >= 0.51) {
      return 2; // Yellow - More than halfway
    } else if (progressPercentage >= 0.26) {
      return 1; // Orange - Started but less than halfway
    } else {
      return 0; // Red - Just started or not started
    }
  }

  // Helper to check if this category has any simulated cases
  bool get hasSimulatedCases => simulatedCount > 0;

  // Get the ratio of actual to simulated cases
  double get actualRatio => currentCount > 0 ? actualCount / currentCount : 1.0;
  double get simulatedRatio =>
      currentCount > 0 ? simulatedCount / currentCount : 0.0;
}

// New class to represent a group of categories
class CoaCategoryGroup {
  final String id;
  final String title;
  final String description;
  final List<String> categoryIds;
  final bool isRequired;
  final String helpText;

  CoaCategoryGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryIds,
    this.isRequired = true,
    this.helpText = '',
  });

  factory CoaCategoryGroup.fromJson(Map<String, dynamic> json) {
    return CoaCategoryGroup(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      categoryIds: List<String>.from(json['categoryIds'] as List),
      isRequired: json['isRequired'] as bool? ?? true,
      helpText: json['helpText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryIds': categoryIds,
      'isRequired': isRequired,
      'helpText': helpText,
    };
  }
}
