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
}
