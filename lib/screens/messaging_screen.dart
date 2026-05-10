import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';

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
  List<Profile> _chats = [];
  List<Map<String, dynamic>> _matchRequests = [];
  bool _isLoadingChats = true;
  bool _isLoadingProfile = true;
  bool _showRequests = false;
  bool _isFetchingInitialProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndChats();
  }

  @override
  void didUpdateWidget(MessagingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('MSG: didUpdateWidget. Old ID: ${oldWidget.initialProfileId}, New ID: ${widget.initialProfileId}');
    if (widget.initialProfileId != oldWidget.initialProfileId && widget.initialProfileId != null) {
      _loadProfileAndChats();
    }
  }

  Future<void> _loadProfileAndChats() async {
    debugPrint('MSG: Loading profile and chats. Initial ID: ${widget.initialProfileId}');
    try {
      if (widget.initialProfileId != null) {
        setState(() => _isFetchingInitialProfile = true);
      }

      final myProfile = await SupabaseService.getMyProfile();
      final chatData = await SupabaseService.getMyChats();
      debugPrint('MSG: Chats loaded: ${chatData.length}');
      
      // Fetch pending match requests where I am the receiver
      final requestData = await SupabaseService.client
          .from('connections')
          .select('*, sender:profiles!sender_id(id, display_name, avatar_url, username)')
          .eq('receiver_id', SupabaseService.client.auth.currentUser!.id)
          .eq('status', 'pending');

      final chats = chatData.map((json) => Profile.fromJson(json)).toList();
      Profile? selectedProfile;
      bool showRequests = _showRequests;

      if (widget.initialProfileId != null) {
        debugPrint('MSG: Searching for initial ID: ${widget.initialProfileId}');
        showRequests = false;
        final existing = chats.where((c) => c.id == widget.initialProfileId);
        if (existing.isNotEmpty) {
          debugPrint('MSG: Found in existing chats');
          selectedProfile = existing.first;
        } else {
          debugPrint('MSG: Not in existing, fetching from profiles table...');
          // Fetch the profile if it's not in chats
          try {
            final data = await SupabaseService.client
                .from('profiles')
                .select()
                .eq('id', widget.initialProfileId!)
                .single();
            final profile = Profile.fromJson(data);
            debugPrint('MSG: Profile fetched: ${profile.displayName}');
            selectedProfile = profile;
            if (!chats.any((c) => c.id == profile.id)) {
              chats.insert(0, profile);
            }
          } catch (e) {
            debugPrint('MSG: Error fetching initial profile: $e');
          }
        }
      } else {
        // Only apply fallback logic if no specific initialProfileId is provided
        if (_selectedProfile != null) {
          selectedProfile = _selectedProfile;
          debugPrint('MSG: Keeping currently selected profile: ${selectedProfile?.displayName}');
        } else if (chats.isNotEmpty) {
          selectedProfile = chats.first;
          debugPrint('MSG: Falling back to first chat: ${selectedProfile?.displayName}');
        }
      }

      setState(() {
        _myProfile = myProfile;
        _chats = chats;
        _selectedProfile = selectedProfile;
        _matchRequests = List<Map<String, dynamic>>.from(requestData);
        _showRequests = showRequests;
        _isLoadingChats = false;
        _isLoadingProfile = false;
        _isFetchingInitialProfile = false;
      });
      debugPrint('MSG: Initialization complete. Selected: ${_selectedProfile?.displayName}');
    } catch (e) {
      debugPrint('MSG: CRITICAL ERROR in _loadProfileAndChats: $e');
      setState(() {
        _isLoadingChats = false;
        _isLoadingProfile = false;
        _isFetchingInitialProfile = false;
      });
    }
  }

  void _handleRequest(String requestId, String status) async {
    await SupabaseService.respondToMatchRequest(requestId, status);
    _loadProfileAndChats(); // Refresh
  }

  void _openChat(Profile profile) {
    debugPrint('MSG: Opening chat with ${profile.displayName}');
    setState(() {
      _selectedProfile = profile;
      // Add to chats list if not already there
      if (!_chats.any((c) => c.id == profile.id)) {
        _chats.insert(0, profile);
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty || _selectedProfile == null) return;
    
    final content = _messageController.text;
    _messageController.clear();
    
    await SupabaseService.sendMessage(_selectedProfile!.id, content);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    // Only show locked state if user is NOT validated AND cannot message anyone
    if (_myProfile != null && !_myProfile!.isValidated && !(_myProfile!.canMessageAnyone ?? false)) {
      return _buildLockedState();
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    // On mobile, if a profile is selected, show only the chat window.
    // Otherwise, show only the contact list.
    if (isMobile) {
      if (_selectedProfile != null) {
        return _buildChatWindow(isMobile: true);
      } else {
        return _buildContactList(isMobile: true);
      }
    }

    // Desktop: Show both side by side
    return Row(
      children: [
        _buildContactList(isMobile: false),
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

  Widget _buildContactList({required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 320,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildTabButton('Messages', !_showRequests),
                const SizedBox(width: 16),
                _buildTabButton('Requests', _showRequests, count: _matchRequests.length),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingChats)
            const Center(child: CircularProgressIndicator(color: OTheme.neonPink))
          else
            Expanded(
              child: _showRequests ? _buildRequestsList() : _buildChatsList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, {int count = 0}) {
    return InkWell(
      onTap: () => setState(() => _showRequests = label == 'Requests'),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white24,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
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

  Widget _buildChatsList() {
    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final profile = _chats[index];
        return ListTile(
          selected: _selectedProfile?.id == profile.id,
          selectedTileColor: OTheme.neonPink.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: CircleAvatar(
            backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            backgroundColor: OTheme.deepCharcoal,
            child: profile.avatarUrl == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
          ),
          title: Text(profile.displayName ?? 'Unknown', style: const TextStyle(color: Colors.white)),
          subtitle: const Text('New message...', style: TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () => _openChat(profile),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                OTheme.neonPink.withOpacity(0.15),
                OTheme.softRose.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OTheme.neonPink.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: OTheme.neonPink.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OTheme.neonPink.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_outline_rounded, color: OTheme.neonPink, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match Guidance',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please only allow requests if you are genuinely interested in connecting with the requester.',
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _matchRequests.length,
            itemBuilder: (context, index) {
              final request = _matchRequests[index];
              final sender = request['sender'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: CircleAvatar(
                  backgroundImage: sender['avatar_url'] != null ? NetworkImage(sender['avatar_url']) : null,
                  backgroundColor: OTheme.deepCharcoal,
                  child: sender['avatar_url'] == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
                ),
                title: Text(sender['display_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                subtitle: Text('@${sender['username']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                      onPressed: () => _handleRequest(request['id'], 'accepted'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: () => _handleRequest(request['id'], 'declined'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatWindow({required bool isMobile}) {
    if (_selectedProfile == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Chat Header
        _buildChatHeader(isMobile: isMobile),
        // Messages
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.getMessagesStream(_selectedProfile!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
              
              final messages = snapshot.data!
                .where((m) => 
                  (m['sender_id'] == _selectedProfile!.id && m['receiver_id'] == SupabaseService.client.auth.currentUser!.id) ||
                  (m['sender_id'] == SupabaseService.client.auth.currentUser!.id && m['receiver_id'] == _selectedProfile!.id)
                ).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final isMe = m['sender_id'] == SupabaseService.client.auth.currentUser!.id;
                  return ChatMessage(text: m['content'], isMe: isMe);
                },
              );
            }
          ),
        ),
        // Input
        _buildInput(),
      ],
    );
  }

  Widget _buildChatHeader({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => setState(() => _selectedProfile = null),
            ),
          CircleAvatar(
            backgroundImage: _selectedProfile?.avatarUrl != null ? NetworkImage(_selectedProfile!.avatarUrl!) : null,
            backgroundColor: OTheme.deepCharcoal,
            child: _selectedProfile?.avatarUrl == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selectedProfile?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: OTheme.deepCharcoal,
            onSelected: (value) {
              if (value == 'block') {
                SupabaseService.blockUser(_selectedProfile!.id);
                setState(() => _selectedProfile = null);
                _loadProfileAndChats(); // Refresh the list
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'block', child: Text('Block User', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: OTheme.deepCharcoal,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: OTheme.neonPink,
            child: const Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_outlined, size: 80, color: OTheme.neonPink.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'Identity Validation Pending',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'O requires a human check before unlocking messaging. You can continue browsing Discovery while we process your photo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _loadProfileAndChats(), // Refresh
            style: ElevatedButton.styleFrom(backgroundColor: OTheme.neonPink),
            child: const Text('Check Status', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatMessage({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? OTheme.neonPink : OTheme.deepCharcoal,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(text, style: TextStyle(color: isMe ? Colors.black : Colors.white)),
      ),
    );
  }
}
