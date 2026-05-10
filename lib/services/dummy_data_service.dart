import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:o_web/services/supabase_service.dart';
import 'dart:math';

class DummyDataService {
  static final SupabaseClient _client = SupabaseService.client;

  static Future<void> seedDummyData() async {
    final random = Random();
    
    // 1. Create Dummy Profiles with Zipcodes and Coordinates
    // New York: 40.7501, -73.9970 (10001)
    // Baltimore: 39.2904, -76.6122 (21201)
    // DC: 38.9072, -77.0369 (20001)

    final List<Map<String, dynamic>> dummyProfiles = [
      {
        'id': 'd0000000-0000-0000-0000-000000000001',
        'username': 'techno_king',
        'display_name': 'Marcus',
        'bio': 'Berlin based producer currently in NYC. Minimal techno & modular synths.',
        'age': 29,
        'pronouns': 'He/Him',
        'interests': ['Techno', 'Design', 'Art'],
        'labels': ['Gay', 'Queer'],
        'is_verified': true,
        'is_validated': true,
        'is_vip': true,
        'zipcode': '10001',
        'latitude': 40.7501,
        'longitude': -73.9970,
        'avatar_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000002',
        'username': 'sarah_starlight',
        'display_name': 'Sarah',
        'bio': 'Digital nomad in Baltimore. Yoga enthusiast. Seeking high vibrations.',
        'age': 26,
        'pronouns': 'She/Her',
        'interests': ['Travel', 'Fitness', 'Coffee'],
        'labels': ['Queer'],
        'is_verified': false,
        'is_validated': true,
        'is_vip': false,
        'zipcode': '21201',
        'latitude': 39.2904,
        'longitude': -76.6122,
        'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000003',
        'username': 'jordan_vines',
        'display_name': 'Jordan',
        'bio': 'Architect in DC. Artist by night. Loves brutalism and red wine.',
        'age': 32,
        'pronouns': 'They/Them',
        'interests': ['Design', 'Art', 'Wine'],
        'labels': ['Non-binary', 'Queer'],
        'is_verified': true,
        'is_validated': true,
        'is_vip': true,
        'zipcode': '20001',
        'latitude': 38.9072,
        'longitude': -77.0369,
        'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000004',
        'username': 'paul_nyc',
        'display_name': 'Paul',
        'bio': 'NYC Native. Looking for coffee and conversation.',
        'age': 24,
        'pronouns': 'He/Him',
        'interests': ['Music', 'Gaming', 'Coffee'],
        'labels': ['Gay'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '10012',
        'latitude': 40.7259,
        'longitude': -73.9983,
        'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000005',
        'username': 'alex_balt',
        'display_name': 'Alex',
        'bio': 'Baltimore based engineer. Into hiking and tech.',
        'age': 28,
        'pronouns': 'He/Him',
        'interests': ['Tech', 'Fitness', 'Outdoors'],
        'labels': ['Queer'],
        'is_verified': true,
        'is_validated': true,
        'zipcode': '21230',
        'latitude': 39.2764,
        'longitude': -76.6107,
        'avatar_url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=400&fit=crop',
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var profile in dummyProfiles) {
      await _client.from('profiles').upsert(profile);
    }

    // 2. Create Dummy Reports
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
    await _client.from('profiles').delete().like('id', 'd0000000-0000-0000-0000-%');
  }
}
