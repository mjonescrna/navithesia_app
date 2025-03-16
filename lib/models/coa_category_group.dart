class CoaCategoryGroup {
  final String id;
  final String title;
  final String description;
  final List<String> categoryIds;

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
