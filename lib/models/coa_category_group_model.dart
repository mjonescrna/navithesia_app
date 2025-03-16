class CoaCategoryGroup {
  final String id;
  final String title;
  final String description;
  final List<String> categoryIds;

  // Add name getter that returns title for compatibility
  String get name => title;

  // Add categories getter that returns empty list for compatibility
  // This will be populated by the widget when needed
  List<dynamic> get categories => [];

  const CoaCategoryGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryIds,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoaCategoryGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
