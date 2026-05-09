import 'package:supabase_flutter/supabase_flutter.dart';

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
  final double? latitude;
  final double? longitude;
  final bool isAdmin;
  final bool isVerified;
  final bool isVip;
  final String? activePathway;

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
    this.latitude,
    this.longitude,
    this.isAdmin = false,
    this.isVerified = false,
    this.isVip = false,
    this.activePathway,
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
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isAdmin: json['is_admin'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isVip: json['is_vip'] ?? false,
      activePathway: json['active_pathway'],
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
      'latitude': latitude,
      'longitude': longitude,
      'active_pathway': activePathway,
    };
  bool get isComplete {
    return displayName != null && 
           age != null && 
           pronouns != null && 
           (interests != null && interests!.isNotEmpty);
  }
}

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://gkwumodalptoyzrvyxxi.supabase.co',
      anonKey: 'sb_publishable_CTZOnxJ7PusFyXsoiWKEWw_mN4Rr_a7',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Auth Logic
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Shared Logic Methods
  static Future<Profile?> getMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final data = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return Profile.fromJson(data);
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final fullUpdates = {...updates, 'id': user.id};

    await client
        .from('profiles')
        .upsert(fullUpdates);
  }

  static Stream<List<Map<String, dynamic>>> getNearbyVines() {
    // In production, this would use a PostGIS RPC call like the mobile app
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('updated_at');
  }

  // Matchmaker Logic
  static Future<Map<String, dynamic>?> getMatchmakerOptIn() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final data = await client
        .from('matchmaker_opt_ins')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    return data;
  }

  static Future<void> saveMatchmakerOptIn(int maxDistance, List<String> intents) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('matchmaker_opt_ins').upsert({
      'user_id': user.id,
      'max_distance': maxDistance,
      'intents': intents,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Profile>> findMatchmakerCandidates(int maxDistance, List<String> intents) async {
    final response = await client.rpc('find_matchmaker_candidates', params: {
      'p_max_distance': maxDistance,
      'p_intents': intents.isEmpty ? null : intents,
      'p_limit': 20,
    });
    
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }
}
