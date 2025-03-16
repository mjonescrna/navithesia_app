class CoaCategory {
  final String id;
  final String name;
  final int requiredCount;
  final String description;
  final String group;
  final bool isRequired;

  const CoaCategory({
    required this.id,
    required this.name,
    required this.requiredCount,
    required this.description,
    required this.group,
    required this.isRequired,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoaCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
