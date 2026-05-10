import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:o_web/models/profile.dart';
import 'package:o_web/models/hub_post.dart';

export 'package:o_web/models/profile.dart';
export 'package:o_web/models/hub_post.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://gkwumodalptoyzrvyxxi.supabase.co',
      anonKey: 'sb_publishable_CTZOnxJ7PusFyXsoiWKEWw_mN4Rr_a7',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Auth Logic
  static Future<AuthResponse> signIn(String identifier, String password) async {
    String email = identifier.trim();
    
    // Check if identifier is an email. Simple regex check.
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      // If not an email, assume it's a username and fetch the linked email via secure RPC
      try {
        final String? linkedEmail = await client.rpc('get_email_from_username', params: {
          'target_username': email,
        });
        
        if (linkedEmail != null) {
          email = linkedEmail;
        }
      } catch (e) {
        debugPrint('Secure lookup failed: $e');
        // Fallback to original identifier if RPC fails
      }
    }
    
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<bool> isUsernameAvailable(String username) async {
    final response = await client
        .from('profiles')
        .select('id')
        .eq('username', username.trim())
        .maybeSingle();
    
    return response == null;
  }

  // Shared Logic Methods
  static Future<Profile?> getMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  static Future<Profile?> getProfile(String id) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching profile $id: $e');
      return null;
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final fullUpdates = {
      ...updates, 
      'id': user.id,
    };

    await client
        .from('profiles')
        .upsert(fullUpdates);
  }

  static Future<String> uploadAvatar(String userId, Uint8List bytes, String fileName) async {
    final path = '$userId/$fileName';
    
    await client.storage
        .from('avatars')
        .uploadBinary(path, bytes);

    return client.storage
        .from('avatars')
        .getPublicUrl(path);
  }

  // Messaging Logic
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    // Security: RLS policies on the 'messages' table now ensure that we only 
    // receive messages where the current user is either the sender or receiver.
    // Performance: We stream the table and let the UI handle the specific 
    // conversation filtering to maintain real-time responsiveness for all active chats.
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  static Future<void> sendMessage(String receiverId, String content) async {
    final myId = client.auth.currentUser!.id;
    await client.from('messages').insert({
      'sender_id': myId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  static Future<List<Map<String, dynamic>>> getMyChats() async {
    final myId = client.auth.currentUser!.id;
    // This fetches unique profiles you've interacted with
    final response = await client.rpc('get_my_chats');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> extendVine(String targetUserId) async {
    final myId = client.auth.currentUser!.id;
    await client.from('connections').upsert({
      'sender_id': myId,
      'receiver_id': targetUserId,
      'status': 'pending',
    });
  }

  static Future<void> respondToMatchRequest(String requestId, String status) async {
    await client.from('connections').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  static Stream<List<Map<String, dynamic>>> getConnectionsStream() {
    return client
        .from('connections')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Safety Logic
  static Future<void> blockUser(String targetUserId) async {
    final myId = client.auth.currentUser!.id;
    await client.from('blocked_users').insert({
      'blocker_id': myId,
      'blocked_id': targetUserId,
    });
  }

  static Future<void> reportUser(String targetUserId, String reason, String details) async {
    final myId = client.auth.currentUser!.id;
    await client.from('reports').insert({
      'reporter_id': myId,
      'reported_id': targetUserId,
      'reason': reason,
      'details': details,
    });
  }

  static Future<void> submitThumbsDown(String targetUserId) async {
    final myId = client.auth.currentUser!.id;
    
    // Check if report already exists to prevent duplicates
    final existing = await client.from('reputation_reports')
        .select()
        .eq('reporter_id', myId)
        .eq('target_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You have already reported this user.');
    }

    await client.from('reputation_reports').insert({
      'reporter_id': myId,
      'target_id': targetUserId,
    });
  }

  static Future<List<Map<String, dynamic>>> getReputationAlerts() async {
    // Fetches users with the highest thumbs down counts for the Admin Console
    final response = await client.from('profiles')
        .select('*, reputation_reports!target_id(count)')
        .order('id'); // We'll process the count in Flutter or via a View
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> savePushToken(String token) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    
    await client.from('user_push_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'device_type': 'web',
    });
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
    try {
      final response = await client.rpc('find_matchmaker_candidates', params: {
        'p_max_distance': maxDistance,
        'p_intents': intents.isEmpty ? null : intents,
        'p_limit': 20,
      });
      return (response as List).map<Profile>((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback: Just fetch some validated profiles if RPC fails
      // In a real app, this would be a more complex geo-query
      final response = await client
          .from('profiles')
          .select()
          .eq('is_validated', true)
          .limit(10);
      
      final candidates = (response as List).map<Profile>((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
      // Filter out self
      final myId = client.auth.currentUser?.id;
      return candidates.where((p) => p.id != myId).toList();
    }
  }

  // Storage Logic
  static Future<String> uploadValidationPhoto(List<int> bytes, String extension) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final path = '${user.id}/validation_${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    await client.storage.from('validation').uploadBinary(path, Uint8List.fromList(bytes));
    
    return client.storage.from('validation').getPublicUrl(path);
  }

  static Future<void> createProfile(Profile profile) async {
    final json = profile.toJson();
    // Security: Remove sensitive flags if present to prevent self-promotion
    json.remove('is_admin');
    json.remove('is_verified');
    json.remove('is_vip');
    
    await client.from('profiles').insert(json);
  }

  static Future<void> promoteToAdmin(String username) async {
    // Only a super-admin should be calling this via the UI
    final response = await client
        .from('profiles')
        .select('id')
        .ilike('username', username.trim())
        .maybeSingle();
    
    if (response == null) throw Exception('User "@$username" not found');
    
    await client
        .from('profiles')
        .update({'is_admin': true})
        .eq('id', response['id']);
  }

  // Hub Content Logic
  static Future<List<HubPost>> getHubPosts() async {
    try {
      final response = await client
          .from('hub_posts')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => HubPost.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching hub posts: $e');
      return []; // Return empty if table doesn't exist yet
    }
  }

  static Future<void> createHubPost(HubPost post) async {
    await client.from('hub_posts').insert(post.toJson());
  }

  static Future<void> updateHubPost(HubPost post) async {
    await client.from('hub_posts').update(post.toJson()).eq('id', post.id);
  }

  static Future<void> deleteHubPost(String id) async {
    await client.from('hub_posts').delete().eq('id', id);
  }

  static Future<String> uploadHubMedia(Uint8List bytes, String fileName) async {
    final path = 'hub/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    // Using dedicated 'hub_content' bucket for platform news and updates.
    try {
      await client.storage
          .from('hub_content')
          .uploadBinary(path, bytes);

      return client.storage
          .from('hub_content')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading hub media: $e');
      rethrow;
    }
  }

  // Verification Flow Logic
  static Future<void> submitVerification(Uint8List bytes, String fileName) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final path = '${user.id}/$fileName';
    
    // 1. Upload to private 'verification_ids' bucket
    await client.storage
        .from('verification_ids')
        .uploadBinary(path, bytes);

    // 2. Get the URL (private, but we store the path or signed URL later)
    // For admins, we will generate a signed URL on demand.
    final imageUrl = path; 

    // 3. Create application record
    await client.from('verification_applications').insert({
      'user_id': user.id,
      'id_image_url': imageUrl,
      'status': 'pending',
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    final response = await client
        .from('verification_applications')
        .select('*, profiles(display_name, username, avatar_url)')
        .eq('status', 'pending')
        .order('created_at');
    
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateVerificationStatus(String id, String status, {String? notes}) async {
    await client
        .from('verification_applications')
        .update({
          'status': status,
          'admin_notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<String> getVerificationIdUrl(String path) async {
    // Generate a signed URL for the admin to view the ID securely
    return await client.storage
        .from('verification_ids')
        .createSignedUrl(path, 60); // Valid for 60 seconds
  }

  static Future<Map<String, dynamic>?> getMyVerificationApplication() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('verification_applications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response;
  }

  // Privacy & Legal Logic
  static Future<void> deleteAccount() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    // Supabase RLS and cascading deletes should handle most of this, 
    // but we explicitly clean up major tables to be safe.
    await client.from('messages').delete().or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');
    await client.from('connections').delete().or('user1_id.eq.${user.id},user2_id.eq.${user.id}');
    await client.from('hub_posts').delete().eq('id', user.id); // If user is an admin
    await client.from('profiles').delete().eq('id', user.id);
    
    await client.auth.signOut();
  }

  static Future<Map<String, dynamic>> exportUserData() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profile = await getMyProfile();
    final connections = await client.from('connections').select().or('user1_id.eq.${user.id},user2_id.eq.${user.id}');
    final messages = await client.from('messages').select().or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');

    return {
      'export_date': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'connections_count': connections.length,
      'messages_count': messages.length,
      'notice': 'This export contains your primary profile data and activity counts. For a full message log, contact support.',
    };
  }
}
