import 'package:isar/isar.dart';

part 'tag.g.dart';

@collection
class Tag {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? color; // Hex string, e.g., "#FF0000"

  Tag({required this.name, this.color});
}
