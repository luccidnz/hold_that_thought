class Note {
  const Note({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String? body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final List<String> tags;

  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }
}
