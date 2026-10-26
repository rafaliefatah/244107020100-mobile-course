class Note {
  const Note({
    required this.title,
    required this.updatedAt,
    this.body = '',
  });

  final String title;
  final String body;
  final DateTime updatedAt;
}
