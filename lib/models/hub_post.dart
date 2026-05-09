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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'image_url': imageUrl,
      'tag': tag,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HubPost copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? content,
    String? imageUrl,
    String? tag,
    HubPostType? type,
    DateTime? createdAt,
  }) {
    return HubPost(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
