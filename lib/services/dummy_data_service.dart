import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:o_web/services/supabase_service.dart';
import 'dart:math';

class DummyDataService {
  static final SupabaseClient _client = SupabaseService.client;

  static Future<void> seedDummyData() async {
    final currentUserId = _client.auth.currentUser?.id;
    final now = DateTime.now();
    final random = Random();

    // 1. Comprehensive Dummy Profiles
    final List<Map<String, dynamic>> dummyProfiles = [
      {
        'id': 'd0000000-0000-0000-0000-000000000001',
        'username': 'techno_king',
        'display_name': 'Marcus',
        'bio': 'Berlin based producer currently in NYC. Minimal techno & modular synths. Let\'s explore the underground scene.',
        'age': 29,
        'pronouns': 'He/Him',
        'interests': ['Techno', 'Design', 'Art', 'Nightlife'],
        'labels': ['Gay', 'Queer', 'Fisting:3', 'Leather:4', 'BDSM:2'],
        'is_verified': true,
        'is_validated': true,
        'is_premium': true,
        'zipcode': '10001',
        'latitude': 40.7501,
        'longitude': -73.9970,
        'avatar_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
        'gallery_urls': [
          'https://images.unsplash.com/photo-1550029330-8dbccaade873?w=800',
          'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=800'
        ],
        'prompts': {'What I\'m looking for': 'Someone who appreciates a deep bassline and early mornings.'},
        'is_online': true,
        'last_active': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000002',
        'username': 'sarah_starlight',
        'display_name': 'Sarah',
        'bio': 'Digital nomad in Baltimore. Yoga enthusiast. Seeking high vibrations and meaningful connections.',
        'age': 26,
        'pronouns': 'She/Her',
        'interests': ['Travel', 'Fitness', 'Coffee', 'Yoga'],
        'labels': ['Queer', 'Poly'],
        'is_verified': false,
        'is_validated': true,
        'is_premium': false,
        'zipcode': '21201',
        'latitude': 39.2904,
        'longitude': -76.6122,
        'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
        'is_online': false,
        'last_active': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000003',
        'username': 'jordan_vines',
        'display_name': 'Jordan',
        'bio': 'Architect in DC. Artist by night. Loves brutalism, red wine, and deep conversations about urban planning.',
        'age': 32,
        'pronouns': 'They/Them',
        'interests': ['Design', 'Art', 'Wine', 'Architecture'],
        'labels': ['Non-binary', 'Queer', 'Bondage:1', 'Dom/Sub:3'],
        'is_verified': true,
        'is_validated': true,
        'is_premium': true,
        'zipcode': '20001',
        'latitude': 38.9072,
        'longitude': -77.0369,
        'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        'gallery_urls': ['https://images.unsplash.com/photo-1481349518771-20055b2a7b24?w=800'],
        'is_online': true,
        'last_active': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000004',
        'username': 'paul_nyc',
        'display_name': 'Paul',
        'bio': 'NYC Native. Looking for coffee and conversation. I know all the best hidden spots in the West Village.',
        'age': 24,
        'pronouns': 'He/Him',
        'interests': ['Music', 'Gaming', 'Coffee', 'Cinema'],
        'labels': ['Gay', 'Roleplay:2', 'Uniforms:4'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '10012',
        'latitude': 40.7259,
        'longitude': -73.9983,
        'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
        'is_online': true,
        'last_active': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000005',
        'username': 'alex_balt',
        'display_name': 'Alex',
        'bio': 'Baltimore based engineer. Into hiking, tech, and the occasional rave. Always down for an adventure.',
        'age': 28,
        'pronouns': 'He/Him',
        'interests': ['Tech', 'Fitness', 'Outdoors', 'Hiking'],
        'labels': ['Queer', 'Leather:2', 'Jockstrap:4'],
        'is_verified': true,
        'is_validated': true,
        'zipcode': '21230',
        'latitude': 39.2764,
        'longitude': -76.6107,
        'avatar_url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=400&fit=crop',
        'is_online': false,
        'last_active': now.subtract(const Duration(days: 1)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000006',
        'username': 'ocean_eyes',
        'display_name': 'Finn',
        'bio': 'Surfer and ocean lover. Just moved to the city and missing the waves.',
        'age': 22,
        'pronouns': 'He/Him',
        'interests': ['Outdoors', 'Fitness', 'Music'],
        'labels': ['Gay', 'Puppy Play:0'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '10001',
        'latitude': 40.7501,
        'longitude': -73.9970,
        'avatar_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000007',
        'username': 'chef_d',
        'display_name': 'Dimitri',
        'bio': 'Professional chef. I can cook you the best meal of your life, but I might be a bit of a kitchen tyrant.',
        'age': 35,
        'pronouns': 'He/Him',
        'interests': ['Foodie', 'Wine', 'Travel'],
        'labels': ['Gay', 'Master/Slave:4', 'Impact Play:3'],
        'is_verified': true,
        'is_validated': true,
        'is_premium': true,
        'zipcode': '20005',
        'latitude': 38.9050,
        'longitude': -77.0320,
        'avatar_url': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000008',
        'username': 'creative_soul',
        'display_name': 'Leo',
        'bio': 'Graphic designer and illustrator. Always carry a sketchbook.',
        'age': 27,
        'pronouns': 'He/They',
        'interests': ['Design', 'Art', 'Books', 'Cinema'],
        'labels': ['Queer', 'Roleplay:2', 'Dom/Sub:1'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '11201',
        'latitude': 40.6936,
        'longitude': -73.9857,
        'avatar_url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000009',
        'username': 'fitness_freak',
        'display_name': 'Chris',
        'bio': 'Personal trainer. Let\'s hit the gym then grab a protein shake.',
        'age': 31,
        'pronouns': 'He/Him',
        'interests': ['Fitness', 'Tech', 'Hiking'],
        'labels': ['Gay', 'Sports Gear:4', 'Muscle Worship:4'],
        'is_verified': true,
        'is_validated': true,
        'zipcode': '20002',
        'latitude': 38.8951,
        'longitude': -76.9942,
        'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000010',
        'username': 'bookworm_ben',
        'display_name': 'Ben',
        'bio': 'PhD student in History. I spend most of my time in libraries or quiet cafes. Let\'s talk about the past.',
        'age': 29,
        'pronouns': 'He/Him',
        'interests': ['Books', 'Art', 'Coffee', 'Architecture'],
        'labels': ['Gay', 'Uniforms:1', 'Bondage:0'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '10027',
        'latitude': 40.8116,
        'longitude': -73.9548,
        'avatar_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000011',
        'username': 'night_owl',
        'display_name': 'Sasha',
        'bio': 'Sleepless in Seattle (but actually in NYC). I live for the night and the neon lights.',
        'age': 25,
        'pronouns': 'They/Them',
        'interests': ['Nightlife', 'Techno', 'Design'],
        'labels': ['Non-binary', 'Queer', 'Leather:3', 'Impact Play:2'],
        'is_verified': true,
        'is_validated': true,
        'zipcode': '10002',
        'latitude': 40.7128,
        'longitude': -74.0060,
        'avatar_url': 'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000012',
        'username': 'mountain_man',
        'display_name': 'Gabe',
        'bio': 'Rugged and ready for the trail. I build things with my hands and climb mountains for fun.',
        'age': 38,
        'pronouns': 'He/Him',
        'interests': ['Outdoors', 'Hiking', 'Tech'],
        'labels': ['Gay', 'Master/Slave:3', 'BDSM:4'],
        'is_verified': true,
        'is_validated': true,
        'is_premium': true,
        'zipcode': '21201',
        'latitude': 39.2904,
        'longitude': -76.6122,
        'avatar_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000013',
        'username': 'pixel_perfect',
        'display_name': 'Julian',
        'bio': 'Game dev and synth enthusiast. My setup is probably cooler than yours.',
        'age': 30,
        'pronouns': 'He/Him',
        'interests': ['Gaming', 'Tech', 'Music', 'Design'],
        'labels': ['Queer', 'Roleplay:4', 'Sensory Deprivation:3'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '20001',
        'latitude': 38.9072,
        'longitude': -77.0369,
        'avatar_url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000014',
        'username': 'jazz_junkie',
        'display_name': 'Miles',
        'bio': 'Saxophone player and jazz aficionado. Let\'s find a smoky bar and listen to some Coltrane.',
        'age': 45,
        'pronouns': 'He/Him',
        'interests': ['Music', 'Wine', 'Books', 'Cinema'],
        'labels': ['Gay', 'Daddy/Son:4'],
        'is_verified': true,
        'is_validated': true,
        'zipcode': '10025',
        'latitude': 40.7980,
        'longitude': -73.9680,
        'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
      {
        'id': 'd0000000-0000-0000-0000-000000000015',
        'username': 'urban_explorer',
        'display_name': 'Toby',
        'bio': 'Always finding the forgotten corners of the city. Photographer and historian.',
        'age': 28,
        'pronouns': 'He/They',
        'interests': ['Art', 'Design', 'Architecture', 'Travel'],
        'labels': ['Queer', 'Fisting:2', 'Bondage:2'],
        'is_verified': false,
        'is_validated': true,
        'zipcode': '21211',
        'latitude': 39.3308,
        'longitude': -76.6341,
        'avatar_url': 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=400&h=400&fit=crop',
        'updated_at': now.toIso8601String(),
      },
    ];

    for (var profile in dummyProfiles) {
      await _client.from('profiles').upsert(profile);
    }

    // 2. Hub Posts
    final dummyPosts = [
      {
        'id': 'a0000000-0000-0000-0000-000000000001',
        'title': 'Welcome to the New O Web',
        'subtitle': 'Experience the full power of O on your desktop. Faster, sleeker, and more intuitive.',
        'image_url': 'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?auto=format&fit=crop&q=80&w=1000',
        'tag': 'NEW FEATURE',
        'type': 'featured',
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'a0000000-0000-0000-0000-000000000002',
        'title': 'Enhanced Privacy Controls',
        'subtitle': 'We\'ve added more granular controls over who can see your profile details.',
        'tag': 'SECURITY',
        'type': 'update',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'a0000000-0000-0000-0000-000000000003',
        'title': 'FistFest 2026: Official Partner',
        'subtitle': 'O is proud to be the official networking partner for FistFest this year. Get ready for exclusive events!',
        'image_url': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1000',
        'tag': 'EVENT',
        'type': 'featured',
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'a0000000-0000-0000-0000-000000000004',
        'title': 'O Premium: Coming Soon',
        'subtitle': 'Unlock exclusive features like unlimited swipes, priority matching, and advanced filters.',
        'tag': 'PREMIUM',
        'type': 'comingSoon',
        'created_at': now.toIso8601String(),
      },
    ];

    for (var post in dummyPosts) {
      await _client.from('hub_posts').upsert(post);
    }

    // 3. Connections & Messages (Interactions)
    if (currentUserId != null) {
      // Clear old connections to avoid messy UAT state
      await _client.from('connections').delete().or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId');

      // Add a mix of connections for the current user
      final connections = [
        // Accepted connection with Marcus (Conversation)
        {
          'sender_id': 'd0000000-0000-0000-0000-000000000001',
          'receiver_id': currentUserId,
          'status': 'accepted',
          'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
        // Pending request from Jordan
        {
          'sender_id': 'd0000000-0000-0000-0000-000000000003',
          'receiver_id': currentUserId,
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
        },
        // Request SENT to Paul
        {
          'sender_id': currentUserId,
          'receiver_id': 'd0000000-0000-0000-0000-000000000004',
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 12)).toIso8601String(),
        },
      ];

      for (var conn in connections) {
        await _client.from('connections').upsert(conn, onConflict: 'sender_id, receiver_id');
      }

      // Add messages for the accepted connection with Marcus
      final messages = [
        {
          'sender_id': 'd0000000-0000-0000-0000-000000000001',
          'receiver_id': currentUserId,
          'content': 'Hey! Saw you were also into techno. Have you been to the new spot in Brooklyn?',
          'created_at': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        },
        {
          'sender_id': currentUserId,
          'receiver_id': 'd0000000-0000-0000-0000-000000000001',
          'content': 'Hey Marcus! Not yet, I\'ve heard great things though. Is it worth the trek?',
          'created_at': now.subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
        },
        {
          'sender_id': 'd0000000-0000-0000-0000-000000000001',
          'receiver_id': currentUserId,
          'content': 'Absolutely. The sound system is incredible. We should go sometime!',
          'created_at': now.subtract(const Duration(hours: 20)).toIso8601String(),
        },
        {
          'sender_id': 'd0000000-0000-0000-0000-000000000001',
          'receiver_id': currentUserId,
          'content': 'Here\'s a photo of the booth.',
          'media_url': 'https://images.unsplash.com/photo-1571266028243-e4733b0f0bb1?w=800',
          'media_type': 'image',
          'created_at': now.subtract(const Duration(hours: 19)).toIso8601String(),
        },
      ];

      for (var msg in messages) {
        await _client.from('messages').insert(msg);
      }
    }

    // 4. Notifications
    if (currentUserId != null) {
      final notifications = [
        {
          'user_id': currentUserId,
          'type': 'match',
          'title': 'New Vine Extension!',
          'body': 'Marcus extended a vine to you. Start the conversation!',
          'data': {'sender_id': 'd0000000-0000-0000-0000-000000000001'},
          'is_read': false,
          'created_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        },
        {
          'user_id': currentUserId,
          'type': 'message',
          'title': 'New Message from Sarah',
          'body': 'Hey, are you coming to yoga tomorrow?',
          'data': {'sender_id': 'd0000000-0000-0000-0000-000000000002'},
          'is_read': true,
          'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
        },
        {
          'user_id': currentUserId,
          'type': 'verification',
          'title': 'Account Validated',
          'body': 'Your identity has been verified. Welcome to the inner circle.',
          'is_read': true,
          'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        },
      ];

      for (var notif in notifications) {
        await _client.from('notifications').insert(notif);
      }
    }

    // 5. Matchmaker Opt-ins (Seed for all dummy profiles)
    for (var profile in dummyProfiles) {
      await _client.from('matchmaker_opt_ins').upsert({
        'user_id': profile['id'],
        'max_distance': 50 + random.nextInt(50),
        'intents': ['Friends', 'Dating', 'Networking'],
        'is_active': true,
        'updated_at': now.toIso8601String(),
      });
    }

    // 6. Moderation & Safety
    if (currentUserId != null) {
      // A report BY the current user
      await _client.from('reports').upsert({
        'reporter_id': currentUserId,
        'reported_id': 'd0000000-0000-0000-0000-000000000005', // Alex
        'reason': 'Suspicious behavior',
        'details': 'UAT: Testing report functionality.',
        'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      });

      // Some reputation reports (thumbs down) for testing admin view
      await _client.from('reputation_reports').upsert({
        'reporter_id': 'd0000000-0000-0000-0000-000000000002',
        'target_id': 'd0000000-0000-0000-0000-000000000010', // Ben
      });
      await _client.from('reputation_reports').upsert({
        'reporter_id': 'd0000000-0000-0000-0000-000000000003',
        'target_id': 'd0000000-0000-0000-0000-000000000010', // Ben
      });
    }

    // 7. Verification Applications (for Admin Screen UAT)
    final verifications = [
      {
        'user_id': 'd0000000-0000-0000-0000-000000000006', // Finn
        'id_image_url': 'https://images.unsplash.com/photo-1554151228-14d9def656e4?w=800',
        'status': 'pending',
        'created_at': now.subtract(const Duration(hours: 8)).toIso8601String(),
      },
      {
        'user_id': 'd0000000-0000-0000-0000-000000000008', // Leo
        'id_image_url': 'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=800',
        'status': 'pending',
        'created_at': now.subtract(const Duration(hours: 12)).toIso8601String(),
      },
    ];

    for (var v in verifications) {
      await _client.from('verification_applications').upsert(v, onConflict: 'user_id');
    }

    // 8. Profile Views (Who Viewed Me)
    if (currentUserId != null) {
      final views = [
        {'viewer_id': 'd0000000-0000-0000-0000-000000000001', 'viewed_id': currentUserId, 'viewed_at': now.subtract(const Duration(minutes: 10)).toIso8601String()},
        {'viewer_id': 'd0000000-0000-0000-0000-000000000003', 'viewed_id': currentUserId, 'viewed_at': now.subtract(const Duration(hours: 2)).toIso8601String()},
        {'viewer_id': 'd0000000-0000-0000-0000-000000000007', 'viewed_id': currentUserId, 'viewed_at': now.subtract(const Duration(hours: 5)).toIso8601String()},
      ];
      for (var view in views) {
        await _client.from('profile_views').upsert(view, onConflict: 'viewer_id, viewed_id');
      }
    }

    // 9. Endorsements
    if (currentUserId != null) {
      final endorsements = [
        {'endorser_id': 'd0000000-0000-0000-0000-000000000001', 'endorsed_id': currentUserId, 'status': 'approved', 'content': 'Amazing connection, highly recommend!', 'created_at': now.subtract(const Duration(days: 2)).toIso8601String()},
        {'endorser_id': 'd0000000-0000-0000-0000-000000000003', 'endorsed_id': currentUserId, 'status': 'approved', 'content': 'Such a great guy to hang out with.', 'created_at': now.subtract(const Duration(days: 5)).toIso8601String()},
        {'endorser_id': 'd0000000-0000-0000-0000-000000000004', 'endorsed_id': currentUserId, 'status': 'pending', 'content': 'Vouching for him!', 'created_at': now.subtract(const Duration(hours: 3)).toIso8601String()},
      ];
      for (var endorsement in endorsements) {
        await _client.from('endorsements').upsert(endorsement, onConflict: 'endorser_id, endorsed_id');
      }
    }
  }

  static Future<void> clearDummyData() async {
    // 1. Delete interactions with dummy users (bi-directional)
    await _client.from('messages').delete().or('sender_id.like.d0000000-%,receiver_id.like.d0000000-%');
    await _client.from('connections').delete().or('sender_id.like.d0000000-%,receiver_id.like.d0000000-%');
    await _client.from('profile_views').delete().or('viewer_id.like.d0000000-%,viewed_id.like.d0000000-%');
    await _client.from('endorsements').delete().or('endorser_id.like.d0000000-%,endorsed_id.like.d0000000-%');
    
    // 2. Delete reports related to dummy users
    await _client.from('reports').delete().or('reporter_id.like.d0000000-%,reported_id.like.d0000000-%');
    await _client.from('reputation_reports').delete().or('reporter_id.like.d0000000-%,target_id.like.d0000000-%');

    // 3. Delete dummy specific records
    await _client.from('notifications').delete().like('user_id', 'd0000000-%');
    await _client.from('verification_applications').delete().like('user_id', 'd0000000-%');
    await _client.from('matchmaker_opt_ins').delete().like('user_id', 'd0000000-%');
    
    // 4. Delete the dummy profiles and posts themselves
    await _client.from('profiles').delete().like('id', 'd0000000-%');
    await _client.from('hub_posts').delete().like('id', 'a0000000-%');
  }
}
