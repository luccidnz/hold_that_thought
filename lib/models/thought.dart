import 'package:hive/hive.dart';
part 'thought.g.dart';

@HiveType(typeId: 1)
class Thought {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final DateTime createdAt;
  @HiveField(3)
  final DateTime updatedAt;
  @HiveField(4)
  final bool archived;
  @HiveField(5)
  final List<String> tags;

  Thought({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.tags = const [],
  });

  Thought copyWith({
    String? content,
    DateTime? updatedAt,
    bool? archived,
    List<String>? tags,
  }) =>
      Thought(
        id: id,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archived: archived ?? this.archived,
        tags: tags ?? this.tags,
      );
}
