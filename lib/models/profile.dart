
class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final int? age;
  final String? pronouns;
  final List<String>? interests;
  final List<String>? labels;
  final List<String>? galleryUrls;
  final Map<String, dynamic>? prompts;
  final Map<String, dynamic>? socialLinks;
  final double? latitude;
  final double? longitude;
  final String? zipcode;
  final String? activePathway;
  final bool isValidated;
  final bool isVerified;
  final bool isAdmin;
  final bool isMod;
  final bool isPremium;
  final int thumbsDownCount;

  Profile({
    required this.id,
    this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.age,
    this.pronouns,
    this.interests,
    this.labels,
    this.galleryUrls,
    this.prompts,
    this.socialLinks,
    this.latitude,
    this.longitude,
    this.zipcode,
    this.activePathway,
    this.isValidated = false,
    this.isVerified = false,
    this.isAdmin = false,
    this.isMod = false,
    this.isPremium = false,
    this.thumbsDownCount = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      age: json['age'],
      pronouns: json['pronouns'],
      interests: (json['interests'] as List?)?.cast<String>(),
      labels: (json['labels'] as List?)?.cast<String>(),
      galleryUrls: (json['gallery_urls'] as List?)?.cast<String>(),
      prompts: json['prompts'] as Map<String, dynamic>?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      zipcode: json['zipcode'],
      activePathway: json['active_pathway'],
      isValidated: json['is_validated'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isMod: json['is_mod'] ?? false,
      isPremium: json['is_premium'] ?? false,
      thumbsDownCount: json['reputation_reports'] != null 
          ? (json['reputation_reports'] is List ? (json['reputation_reports'] as List).length : 0)
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'age': age,
      'pronouns': pronouns,
      'interests': interests,
      'labels': labels,
      'gallery_urls': galleryUrls,
      'prompts': prompts,
      'social_links': socialLinks,
      'latitude': latitude,
      'longitude': longitude,
      'zipcode': zipcode,
      'active_pathway': activePathway,
      'is_validated': isValidated,
      'is_verified': isVerified,
      'is_mod': isMod,
      'is_premium': isPremium,
    };
  }

  bool get isComplete {
    return username != null && username!.isNotEmpty && zipcode != null && zipcode!.isNotEmpty;
  }

  bool get canMessageAnyone {
    return isPremium || isAdmin || isMod;
  }
}
