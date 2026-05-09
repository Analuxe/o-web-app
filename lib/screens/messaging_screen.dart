import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  Profile? _selectedProfile;
  final _messageController = TextEditingController();
  List<Profile> _chats = [];
  bool _isLoadingChats = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final data = await SupabaseService.getMyChats();
      setState(() {
        _chats = data.map((json) => Profile.fromJson(json)).toList();
        _isLoadingChats = false;
        if (_chats.isNotEmpty) _selectedProfile = _chats.first;
      });
    } catch (e) {
      setState(() => _isLoadingChats = false);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty || _selectedProfile == null) return;
    
    final content = _messageController.text;
    _messageController.clear();
    
    await SupabaseService.sendMessage(_selectedProfile!.id, content);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Contact List
        Container(
          width: 320,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Messages', style: Theme.of(context).textTheme.displaySmall),
              ),
              if (_isLoadingChats)
                const Center(child: CircularProgressIndicator(color: OTheme.neonPink))
              else
                Expanded(
                  child: ListView.builder(
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
                        onTap: () => setState(() => _selectedProfile = profile),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        // Chat Window
        Expanded(
          child: _selectedProfile == null 
            ? const Center(child: Text('Select a conversation to start chatting', style: TextStyle(color: Colors.white24)))
            : Column(
            children: [
              // Chat Header
              _buildChatHeader(),
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
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
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
          const Icon(Icons.more_vert, color: Colors.white54),
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
