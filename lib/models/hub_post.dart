enum HubPostType {
  featured,
  update,
  promotion,
  comingSoon
}

class HubPost {
  final String id;
  final String title;
  final String? subtitle;
  final String? content;
  final String? imageUrl;
  final String tag;
  final HubPostType type;
  final DateTime createdAt;

  HubPost({
    required this.id,
    required this.title,
    this.subtitle,
    this.content,
    this.imageUrl,
    required this.tag,
    required this.type,
    required this.createdAt,
  });

  factory HubPost.fromJson(Map<String, dynamic> json) {
    return HubPost(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      content: json['content'],
      imageUrl: json['image_url'],
      tag: json['tag'] ?? 'UPDATE',
      type: HubPostType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HubPostType.update,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
