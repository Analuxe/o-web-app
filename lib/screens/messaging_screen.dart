import 'package:o_web/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:o_web/widgets/report_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class MessagingScreen extends StatefulWidget {
  final String? initialProfileId;
  const MessagingScreen({super.key, this.initialProfileId});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  Profile? _selectedProfile;
  Profile? _myProfile;
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  List<Profile> _chats = [];
  List<Profile> _searchResults = [];
  List<Map<String, dynamic>> _matchRequests = [];
  bool _isLoadingChats = true;
  bool _isLoadingProfile = true;
  bool _isSearching = false;
  bool _showRequests = false;
  bool _showVisitors = false;
  bool _isFetchingInitialProfile = false;

  @override
  void initState() {
    super.initState();
    safeLog('MSG: initState. initialProfileId: ${widget.initialProfileId}');
    _loadProfileAndChats();
  }

  @override
  void didUpdateWidget(MessagingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProfileId != oldWidget.initialProfileId) {
      safeLog('MSG: initialProfileId changed from ${oldWidget.initialProfileId} to ${widget.initialProfileId}');
      _loadProfileAndChats();
    }
  }

  Future<void> _loadProfileAndChats() async {
    safeLog('MSG: Starting load. ID: ${widget.initialProfileId}');
    try {
      if (widget.initialProfileId != null) {
        setState(() => _isFetchingInitialProfile = true);
      }

      final myProfile = await SupabaseService.getMyProfile();
      final chatData = await SupabaseService.getMyChats();
      final blockedIds = await SupabaseService.getBlockedUserIds();
      
      // Fetch pending match requests
      final requestData = await SupabaseService.client
          .from('connections')
          .select('*, sender:profiles!sender_id(id, display_name, avatar_url, username)')
          .eq('receiver_id', SupabaseService.client.auth.currentUser!.id)
          .eq('status', 'pending');

      final chats = chatData
          .map((json) => Profile.fromJson(json))
          .where((p) => !blockedIds.contains(p.id))
          .toList();
      Profile? selectedProfile;
      bool showRequests = _showRequests;

      if (widget.initialProfileId != null) {
        safeLog('MSG: Resolving initial ID: ${widget.initialProfileId}');
        showRequests = false;
        final existing = chats.where((c) => c.id == widget.initialProfileId);
        
        if (existing.isNotEmpty) {
          safeLog('MSG: Found user in existing chats');
          selectedProfile = existing.first;
        } else {
          safeLog('MSG: User not in recent chats. Fetching from database...');
          try {
            final data = await SupabaseService.client
                .from('profiles')
                .select()
                .eq('id', widget.initialProfileId!)
                .single();
            final profile = Profile.fromJson(data);
            safeLog('MSG: Successfully fetched ${profile.displayName}');
            selectedProfile = profile;
            // Inject into the top of the chat list for immediate visibility
            if (!chats.any((c) => c.id == profile.id)) {
              chats.insert(0, profile);
            }
          } catch (e) {
            safeLog('MSG: Error fetching profile from DB: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Could not find user ${widget.initialProfileId} in database.'), backgroundColor: Colors.redAccent),
              );
            }
          }
        }
      } else if (chats.isNotEmpty) {
        // Fallback to first recent chat if no ID provided
        selectedProfile = chats.first;
      }

      if (mounted) {
        // Mark messages as read for the auto-selected conversation
        if (selectedProfile != null) {
          SupabaseService.markMessagesAsRead(selectedProfile.id);
        }
        setState(() {
          _myProfile = myProfile;
          _chats = chats;
          _selectedProfile = selectedProfile;
          _matchRequests = List<Map<String, dynamic>>.from(requestData)
              .where((r) => r['sender'] != null && !blockedIds.contains(r['sender']['id']))
              .toList();
          _showRequests = showRequests;
          _isLoadingChats = false;
          _isLoadingProfile = false;
          _isFetchingInitialProfile = false;
        });
      }
      safeLog('MSG: Load complete. Selected: ${_selectedProfile?.displayName ?? "NONE"}');
    } catch (e) {
      safeLog('LOAD PROFILE ERROR: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingChats = false;
          _isLoadingProfile = false;
          _isFetchingInitialProfile = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openChat(Profile profile) {
    safeLog('MSG: Manually opening chat with ${profile.displayName}');
    // Mark their messages to us as read
    SupabaseService.markMessagesAsRead(profile.id);
    setState(() {
      _selectedProfile = profile;
      _searchController.clear();
      _searchResults = [];
      if (!_chats.any((c) => c.id == profile.id)) {
        _chats.insert(0, profile);
      }
    });
  }

  void _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await SupabaseService.client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(10);
      
      final myId = SupabaseService.client.auth.currentUser?.id;
      final blockedIds = await SupabaseService.getBlockedUserIds();
      setState(() {
        _searchResults = (results as List)
            .map((json) => Profile.fromJson(json))
            .where((p) => p.id != myId)
            .where((p) => !blockedIds.contains(p.id))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      safeLog('MSG: Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  void _handleRequest(String requestId, String status) async {
    await SupabaseService.respondToMatchRequest(requestId, status);
    
    // Notify the sender that their request was accepted
    if (status == 'accepted') {
      // Find the sender ID from the request data
      final request = _matchRequests.firstWhere((r) => r['id'] == requestId, orElse: () => {});
      if (request.isNotEmpty && request['sender'] != null) {
        final senderId = request['sender']['id'] as String?;
        if (senderId != null) {
          SupabaseService.notifyMatchAccepted(senderId);
        }
      }
    }
    
    _loadProfileAndChats(); 
  }

  bool _isUploadingImage = false;

  void _pickAndSendImage() async {
    if (_selectedProfile == null) return;
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final myId = SupabaseService.client.auth.currentUser!.id;
        final url = await SupabaseService.uploadChatMedia(myId, bytes, fileName);
        await SupabaseService.sendMessage(_selectedProfile!.id, '', mediaUrl: url, mediaType: 'image');
      } catch (e) {
        safeLog('Error uploading image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending image: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  void _sendMessage() async {
    final content = _messageController.text;
    
    if (_selectedProfile == null) {
      safeLog('MSG: Cannot send. _selectedProfile is NULL');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Profile is null. Cannot send message.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    if (content.isEmpty) {
      safeLog('MSG: Cannot send. Message content is EMPTY');
      return;
    }

    _messageController.clear();
    
    try {
      await SupabaseService.sendMessage(_selectedProfile!.id, content);
      SupabaseService.notifyNewMessage(_selectedProfile!.id);
      safeLog('MSG: Message sent successfully to ${_selectedProfile!.displayName}');
    } catch (e) {
      // Force output to both developer console and standard output
      safeLog('SEND MESSAGE ERROR: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e is PostgrestException ? e.message : e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    // Permission bypass for Admins/Mods/Premium
    final bool canBypass = _myProfile?.canMessageAnyone ?? false;
    if (_myProfile != null && !_myProfile!.isValidated && !canBypass) {
      return _buildLockedState();
    }

    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      if (_selectedProfile != null) {
        return _buildChatWindow(isMobile: true);
      } else {
        return _buildSearchAndTabs(isMobile: true);
      }
    }

    return Row(
      children: [
        _buildSearchAndTabs(isMobile: false),
        Expanded(
          child: _isFetchingInitialProfile 
            ? const Center(child: CircularProgressIndicator(color: OTheme.neonPink))
            : (_selectedProfile == null 
                ? const Center(child: Text('Select a conversation to start chatting', style: TextStyle(color: Colors.white24)))
                : _buildChatWindow(isMobile: false)),
        ),
      ],
    );
  }

  Widget _buildSearchAndTabs({required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 320,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Search usernames...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white24),
                filled: true,
                fillColor: OTheme.deepCharcoal,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildTabButton('Messages', !_showRequests && !_showVisitors && _searchController.text.isEmpty),
                const SizedBox(width: 16),
                _buildTabButton('Requests', _showRequests && !_showVisitors && _searchController.text.isEmpty, count: _matchRequests.length),
                const SizedBox(width: 16),
                _buildTabButton('Visitors', _showVisitors && _searchController.text.isEmpty),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildMainList()),
        ],
      ),
    );
  }

  Widget _buildMainList() {
    if (_searchController.text.isNotEmpty) {
      return _buildSearchResultsList();
    }
    if (_isLoadingChats) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }
    if (_showVisitors) return _buildVisitorsList();
    return _showRequests ? _buildRequestsList() : _buildChatsList();
  }

  Widget _buildSearchResultsList() {
    if (_isSearching) return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    if (_searchResults.isEmpty) return const Center(child: Text('No users found', style: TextStyle(color: Colors.white24)));
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final profile = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            backgroundColor: OTheme.deepCharcoal,
          ),
          title: Text(profile.displayName ?? 'Unknown', style: const TextStyle(color: Colors.white)),
          subtitle: Text('@${profile.username}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () => _openChat(profile),
        );
      },
    );
  }

  Widget _buildTabButton(String label, bool isSelected, {int count = 0}) {
    return InkWell(
      onTap: () {
        setState(() {
          _showRequests = label == 'Requests';
          _showVisitors = label == 'Visitors';
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white24, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: OTheme.neonPink, borderRadius: BorderRadius.circular(10)),
                  child: Text('$count', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (isSelected) Container(height: 2, width: 20, color: OTheme.neonPink),
        ],
      ),
    );
  }

  Widget _buildVisitorsList() {
    return FutureBuilder<List<Profile>>(
      future: SupabaseService.getProfileViewers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white24)));
        }
        final viewers = snapshot.data ?? [];
        if (viewers.isEmpty) {
          return const Center(child: Text('No recent visitors yet.', style: TextStyle(color: Colors.white24)));
        }
        return ListView.builder(
          itemCount: viewers.length,
          itemBuilder: (context, index) {
            final viewer = viewers[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: CircleAvatar(
                backgroundImage: viewer.avatarUrl != null ? NetworkImage(viewer.avatarUrl!) : null,
                backgroundColor: OTheme.deepCharcoal,
                child: viewer.avatarUrl == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
              ),
              title: Text(viewer.displayName ?? 'User', style: const TextStyle(color: Colors.white)),
              subtitle: Text('@${viewer.username ?? 'user'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
              onTap: () => context.push('/profile/${viewer.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildChatsList() {
    if (_chats.isEmpty) return const Center(child: Text('No conversations yet', style: TextStyle(color: Colors.white24)));
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getUnreadMessagesStream(),
      builder: (context, unreadSnapshot) {
        // Build a map of sender_id -> unread count
        final unreadCounts = <String, int>{};
        if (unreadSnapshot.hasData) {
          for (final msg in unreadSnapshot.data!) {
            if (msg['is_read'] == false) {
              final senderId = msg['sender_id'] as String;
              unreadCounts[senderId] = (unreadCounts[senderId] ?? 0) + 1;
            }
          }
        }

        return ListView.builder(
          itemCount: _chats.length,
          itemBuilder: (context, index) {
            final profile = _chats[index];
            final unread = unreadCounts[profile.id] ?? 0;
            
            return ListTile(
              selected: _selectedProfile?.id == profile.id,
              selectedTileColor: OTheme.neonPink.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: StreamBuilder<Profile?>(
                stream: SupabaseService.getProfileStream(profile.id),
                initialData: profile,
                builder: (context, profileSnapshot) {
                  final liveProfile = profileSnapshot.data ?? profile;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundImage: liveProfile.avatarUrl != null ? NetworkImage(liveProfile.avatarUrl!) : null,
                        backgroundColor: OTheme.deepCharcoal,
                        child: liveProfile.avatarUrl == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
                      ),
                      if (liveProfile.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: OTheme.black, width: 2),
                            ),
                          ),
                        ),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: OTheme.neonPink,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: OTheme.neonPink.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
              title: Text(
                profile.displayName ?? 'Unknown',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                unread > 0 ? '$unread new message${unread == 1 ? '' : 's'}' : 'Direct Message',
                style: TextStyle(
                  color: unread > 0 ? OTheme.neonPink : Colors.white54,
                  fontSize: 12,
                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              onTap: () => _openChat(profile),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    if (_matchRequests.isEmpty) return const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white24)));
    return ListView.builder(
      itemCount: _matchRequests.length,
      itemBuilder: (context, index) {
        final request = _matchRequests[index];
        final sender = request['sender'];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: CircleAvatar(backgroundImage: sender['avatar_url'] != null ? NetworkImage(sender['avatar_url']) : null, backgroundColor: OTheme.deepCharcoal),
          title: Text(sender['display_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
          subtitle: Text('@${sender['username']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check_circle, color: Colors.greenAccent), onPressed: () => _handleRequest(request['id'], 'accepted')),
              IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => _handleRequest(request['id'], 'declined')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatWindow({required bool isMobile}) {
    if (_selectedProfile == null) return const SizedBox.shrink();
    return Column(
      children: [
        _buildChatHeader(isMobile: isMobile),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.getMessagesStream(_selectedProfile!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
              final messages = snapshot.data ?? [];
              // We still do a final filter to ensure we only show messages for the CURRENT active conversation
              // especially if the stream is delivering messages for other chats we're involved in.
              final conversationMessages = messages.where((m) => 
                (m['sender_id'] == _selectedProfile!.id && m['receiver_id'] == SupabaseService.client.auth.currentUser!.id) ||
                (m['sender_id'] == SupabaseService.client.auth.currentUser!.id && m['receiver_id'] == _selectedProfile!.id)
              ).toList();

              if (conversationMessages.isEmpty) return _buildFirstMessageTemplate();

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: conversationMessages.length,
                itemBuilder: (context, index) {
                  final m = conversationMessages[index];
                  final isMe = m['sender_id'] == SupabaseService.client.auth.currentUser!.id;
                  return ChatMessage(
                    text: m['content'] ?? '', 
                    isMe: isMe,
                    mediaUrl: m['media_url'],
                    mediaType: m['media_type'],
                    isRead: isMe ? (m['is_read'] ?? false) : null,
                    isLastFromMe: isMe && index == conversationMessages.length - 1,
                  );
                },
              );
            }
          ),
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: SupabaseService.getMessagesStream(_selectedProfile!.id),
          builder: (context, snapshot) {
            final hasMessages = (snapshot.data ?? []).any((m) => 
              (m['sender_id'] == _selectedProfile!.id && m['receiver_id'] == SupabaseService.client.auth.currentUser!.id) ||
              (m['sender_id'] == SupabaseService.client.auth.currentUser!.id && m['receiver_id'] == _selectedProfile!.id)
            );
            return hasMessages ? _buildInput() : const SizedBox.shrink();
          }
        ),
      ],
    );
  }

  Widget _buildFirstMessageTemplate() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: OTheme.neonPink.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.mail_outline_rounded, color: OTheme.neonPink, size: 40)),
            const SizedBox(height: 24),
            Text('Message ${_selectedProfile?.displayName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Start a direct conversation. Your first message will be delivered immediately.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), height: 1.5)),
            const SizedBox(height: 32),
            TextField(controller: _messageController, maxLines: 4, decoration: InputDecoration(hintText: 'Write your message...', filled: true, fillColor: OTheme.deepCharcoal, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _sendMessage, style: ElevatedButton.styleFrom(backgroundColor: OTheme.neonPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Send Message', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
      child: Row(
        children: [
          if (isMobile) IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => setState(() => _selectedProfile = null)),
          CircleAvatar(backgroundImage: _selectedProfile?.avatarUrl != null ? NetworkImage(_selectedProfile!.avatarUrl!) : null, backgroundColor: OTheme.deepCharcoal),
          const SizedBox(width: 16),
          StreamBuilder<Profile?>(
            stream: SupabaseService.getProfileStream(_selectedProfile!.id),
            initialData: _selectedProfile,
            builder: (context, snapshot) {
              final profile = snapshot.data ?? _selectedProfile;
              final isOnline = profile?.isOnline ?? false;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(profile?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline 
                          ? 'Live' 
                          : (profile?.lastActive != null 
                              ? 'Last active ${_formatRelativeTime(profile!.lastActive!)}'
                              : 'Offline'), 
                        style: TextStyle(
                          fontSize: 12, 
                          color: isOnline ? Colors.green : Colors.white24,
                          fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.white24, size: 20),
            onPressed: () {
              if (_selectedProfile != null) {
                showReportDialog(context, reportedUserId: _selectedProfile!.id);
              }
            },
            tooltip: 'Report User',
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  Widget _buildInput() {
    return Container(padding: const EdgeInsets.all(24), child: Row(children: [
      IconButton(
        icon: _isUploadingImage 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: OTheme.neonPink, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate, color: OTheme.neonPink),
        onPressed: _isUploadingImage ? null : _pickAndSendImage,
      ),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: _messageController, onSubmitted: (_) => _sendMessage(), decoration: InputDecoration(hintText: 'Type a message...', filled: true, fillColor: OTheme.deepCharcoal, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)))),
      const SizedBox(width: 16),
      FloatingActionButton(onPressed: _sendMessage, backgroundColor: OTheme.neonPink, child: const Icon(Icons.send, color: Colors.black)),
    ]));
  }

  Widget _buildLockedState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.lock_person_outlined, size: 80, color: OTheme.neonPink.withValues(alpha: 0.5)),
      const SizedBox(height: 24),
      const Text('Identity Validation Pending', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => _loadProfileAndChats(), style: ElevatedButton.styleFrom(backgroundColor: OTheme.neonPink), child: const Text('Check Status', style: TextStyle(color: Colors.black))),
    ]));
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? mediaUrl;
  final String? mediaType;
  final bool? isRead;
  final bool isLastFromMe;
  const ChatMessage({
    super.key,
    required this.text,
    required this.isMe,
    this.mediaUrl,
    this.mediaType,
    this.isRead,
    this.isLastFromMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final isProposal = mediaType == 'proposal';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, 
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: isLastFromMe ? 4 : 16), 
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
            decoration: BoxDecoration(
              color: isProposal ? null : (isMe ? OTheme.neonPink : OTheme.deepCharcoal),
              gradient: isProposal 
                ? const LinearGradient(
                    colors: [OTheme.neonPink, Color(0xFFFF69B4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16), 
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0)
              ),
              boxShadow: isProposal ? [
                BoxShadow(
                  color: OTheme.neonPink.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ] : null,
            ), 
            constraints: const BoxConstraints(maxWidth: 400), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isProposal) ...[
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'O ADMIN PROPOSAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (mediaUrl != null && mediaType == 'image') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(mediaUrl!, fit: BoxFit.cover),
                  ),
                  if (text.isNotEmpty) const SizedBox(height: 8),
                ],
                if (text.isNotEmpty)
                  Text(
                    text, 
                    style: TextStyle(
                      color: isProposal ? Colors.white : (isMe ? Colors.black : Colors.white), 
                      fontSize: 16,
                      fontWeight: isProposal ? FontWeight.bold : FontWeight.normal,
                    )
                  ),
              ],
            )
          ),
          // Read receipt indicator — only shown on the last message sent by the current user
          if (isMe && isLastFromMe) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRead == true ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead == true ? OTheme.neonPink : Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRead == true ? 'Seen' : 'Sent',
                    style: TextStyle(
                      fontSize: 11,
                      color: isRead == true ? OTheme.neonPink : Colors.white24,
                      fontWeight: isRead == true ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      )
    );
  }
}
