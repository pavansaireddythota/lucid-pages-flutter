class Episode {
  final int id;
  final String title;
  final String content;

  Episode({
    required this.id,
    required this.title,
    required this.content,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }
}