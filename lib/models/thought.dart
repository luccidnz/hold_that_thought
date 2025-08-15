import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'thought.g.dart';

@HiveType(typeId: 0)
class Thought extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime? updatedAt;

  @HiveField(4, defaultValue: false)
  bool pinned;

  @HiveField(5, defaultValue: false)
  bool archived;

  Thought({
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.pinned = false,
    this.archived = false,
  }) {
    id = const Uuid().v4();
  }

  // A factory constructor for creating a new thought with a unique ID.
  factory Thought.create({required String text}) {
    return Thought(
      text: text,
      createdAt: DateTime.now(),
    );
  }
}
