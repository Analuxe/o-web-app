/// Notification types used across the O platform.
enum NotificationType {
  matchRequest,
  matchAccepted,
  newMessage,
  dateProposal,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'],
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// The profile ID of the person who triggered the notification (if any).
  String? get sourceProfileId => data['source_profile_id'] as String?;

  /// The avatar URL of the triggering user (if stored).
  String? get sourceAvatarUrl => data['source_avatar_url'] as String?;

  /// The display name of the triggering user (if stored).
  String? get sourceDisplayName => data['source_display_name'] as String?;

  /// Route to navigate to when the notification is tapped.
  String? get targetRoute => data['route'] as String?;
}
