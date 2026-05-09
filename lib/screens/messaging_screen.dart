import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

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
                child: Text(
                  'Messages',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return const ContactTile();
                  },
                ),
              ),
            ],
          ),
        ),
        // Chat Window
        Expanded(
          child: Column(
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: OTheme.deepCharcoal,
                      child: Icon(Icons.person, color: OTheme.neonPink),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alex',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Online',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.more_vert, color: Colors.white54),
                  ],
                ),
              ),
              // Messages
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    ChatMessage(
                      text: "Hey! Just saw your profile. Love the vibes.",
                      isMe: false,
                    ),
                    ChatMessage(
                      text: "Thanks! Appreciate it. How's your weekend going?",
                      isMe: true,
                    ),
                    ChatMessage(
                      text: "Pretty good, just exploring the city. You?",
                      isMe: false,
                    ),
                  ],
                ),
              ),
              // Input
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: OTheme.deepCharcoal,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: OTheme.neonPink,
                      child: const Icon(Icons.send, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: const CircleAvatar(
        backgroundColor: OTheme.deepCharcoal,
        child: Icon(Icons.person, color: OTheme.neonPink),
      ),
      title: const Text('Alex'),
      subtitle: const Text('Pretty good, just exploring...'),
      trailing: const Text('2m', style: TextStyle(fontSize: 12, color: Colors.white54)),
      onTap: () {},
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
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
