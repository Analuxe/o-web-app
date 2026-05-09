import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:o_web/services/supabase_service.dart';
import 'dart:math';

class DummyDataService {
  static final SupabaseClient _client = SupabaseService.client;

  static Future<void> seedDummyData() async {
    final random = Random();
    
    // 1. Create Dummy Profiles
    // Note: This might fail if RLS is strict on the profiles table for inserts.
    final List<Map<String, dynamic>> dummyProfiles = [
      {
        'id': 'd0000000-0000-0000-0000-000000000001',
        'username': 'techno_king',
        'display_name': 'Marcus',
        'bio': 'Berlin based producer. Minimal techno & modular synths.',
        'age': 29,
        'pronouns': 'He/Him',
        'interests': ['Techno', 'Design', 'Art'],
        'labels': ['Gay', 'Queer'],
        'is_verified': true,
        'is_validated': true,
        'is_vip': true,
        'avatar_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000002',
        'username': 'sarah_starlight',
        'display_name': 'Sarah',
        'bio': 'Digital nomad and yoga enthusiast. Seeking high vibrations.',
        'age': 26,
        'pronouns': 'She/Her',
        'interests': ['Travel', 'Fitness', 'Coffee'],
        'labels': ['Queer'],
        'is_verified': false,
        'is_validated': true,
        'is_vip': false,
        'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000003',
        'username': 'jordan_vines',
        'display_name': 'Jordan',
        'bio': 'Architect by day, artist by night. Loves brutalism and red wine.',
        'age': 32,
        'pronouns': 'They/Them',
        'interests': ['Design', 'Art', 'Wine'],
        'labels': ['Non-binary', 'Queer'],
        'is_verified': true,
        'is_validated': true,
        'is_vip': true,
        'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000004',
        'username': 'pending_paul',
        'display_name': 'Paul',
        'bio': 'Just joined! Hope to meet some cool people.',
        'age': 24,
        'pronouns': 'He/Him',
        'interests': ['Music', 'Gaming'],
        'labels': ['Gay'],
        'is_verified': false,
        'is_validated': false, // For moderation testing
        'is_vip': false,
        'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000005',
        'username': 'glitch_art',
        'display_name': 'Xen',
        'bio': 'Exploring the boundaries of reality through code.',
        'age': 27,
        'pronouns': 'They/Them',
        'interests': ['Tech', 'Design', 'Art'],
        'labels': ['Queer'],
        'is_verified': true,
        'is_validated': true,
        'is_vip': false,
        'avatar_url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var profile in dummyProfiles) {
      await _client.from('profiles').upsert(profile);
    }

    // 2. Create Dummy Reports (for moderation testing)
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId != null) {
      await _client.from('reports').upsert({
        'reporter_id': currentUserId,
        'reported_id': 'd0000000-0000-0000-0000-000000000002',
        'reason': 'Inappropriate content',
        'details': 'Profile contains spam links.',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
    }

    // 3. Create Dummy Matchmaker Data
    for (var profile in dummyProfiles) {
      if (profile['is_validated'] == true) {
        await _client.from('matchmaker_opt_ins').upsert({
          'user_id': profile['id'],
          'max_distance': 50,
          'intents': ['Friends', 'Dating'],
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }

    // 4. Create Dummy Hub Posts
    final dummyPosts = [
      {
        'title': 'Welcome to the New O Web',
        'subtitle': 'Experience the full power of O on your desktop. Faster, sleeker, and more intuitive.',
        'image_url': 'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?auto=format&fit=crop&q=80&w=1000',
        'tag': 'NEW FEATURE',
        'type': 'featured',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Enhanced Privacy Controls',
        'subtitle': 'We\'ve added more granular controls over who can see your profile details.',
        'tag': 'SECURITY',
        'type': 'update',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'title': 'O Premium',
        'subtitle': 'Unlock exclusive features and priority matching.',
        'tag': 'PREMIUM',
        'type': 'comingSoon',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var post in dummyPosts) {
      await _client.from('hub_posts').upsert(post);
    }
  }

  static Future<void> clearDummyData() async {
    // Optional: Add logic to remove dummy data by looking for the 'd000...' prefix
    await _client.from('profiles').delete().like('id', 'd0000000-0000-0000-0000-%');
  }
}
