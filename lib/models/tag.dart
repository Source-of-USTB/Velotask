/// Plain data class used throughout the UI.
/// The actual Drift table definition lives in database.dart (Tags table).
class Tag {
  final int id;
  final String name;
  final String? color;

  const Tag({required this.id, required this.name, this.color});

  /// Convenience: create an unsaved tag (id = 0) for use before insertion.
  const Tag.unsaved({required this.name, this.color}) : id = 0;

  Tag copyWith({int? id, String? name, String? color}) => Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
      );
}
