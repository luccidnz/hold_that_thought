import 'package:hive/hive.dart';

part 'thought.g.dart';

@HiveType(typeId: 0)
class Thought {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime? updatedAt;

  @HiveField(4)
  final bool pinned;

  @HiveField(5)
  final bool archived;

  const Thought({
    required this.id,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.pinned = false,
    this.archived = false,
  });

  Thought copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
    bool? archived,
  }) {
    return Thought(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
    );
  }
}