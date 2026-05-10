import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/models/profile.dart';
import 'package:o_web/services/supabase_service.dart';

class DiscoverySwipeTab extends StatefulWidget {
  final List<Profile> profiles;
  final bool isCurrentUserVerified;

  const DiscoverySwipeTab({
    super.key,
    required this.profiles,
    this.isCurrentUserVerified = false,
  });

  @override
  State<DiscoverySwipeTab> createState() => _DiscoverySwipeTabState();
}

class _DiscoverySwipeTabState extends State<DiscoverySwipeTab> {
  final List<SwipeItem> _swipeItems = [];
  MatchEngine? _matchEngine;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeSwipeItems();
  }

  @override
  void didUpdateWidget(DiscoverySwipeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profiles != oldWidget.profiles) {
      _initializeSwipeItems();
    }
  }

  void _initializeSwipeItems() {
    _swipeItems.clear();
    for (var profile in widget.profiles) {
      _swipeItems.add(
        SwipeItem(
          content: profile,
          likeAction: () {
            SupabaseService.extendVine(profile.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("You liked ${profile.displayName}!"),
                backgroundColor: OTheme.neonPink,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          nopeAction: () {
            // Just move to next
          },
          superlikeAction: () {
             SupabaseService.extendVine(profile.id);
             // Maybe a special effect here?
          },
        ),
      );
    }

    if (_swipeItems.isNotEmpty) {
      _matchEngine = MatchEngine(swipeItems: _swipeItems);
      _isFinished = false;
    } else {
      _isFinished = true;
    }
    
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished || _matchEngine == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              "No more vines to swipe!",
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SwipeCards(
              matchEngine: _matchEngine!,
              itemBuilder: (BuildContext context, int index) {
                final profile = _swipeItems[index].content as Profile;
                return _SwipeCard(profile: profile);
              },
              onStackFinished: () {
                setState(() {
                  _isFinished = true;
                });
              },
              itemChanged: (SwipeItem item, int index) {
                // Handle item change if needed
              },
              upSwipeAllowed: true,
              fillSpace: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: Colors.redAccent,
                onPressed: () => _matchEngine!.currentItem?.nope(),
              ),
              _ActionButton(
                icon: Icons.star,
                color: Colors.blueAccent,
                onPressed: () => _matchEngine!.currentItem?.superlike(),
                isSmall: true,
              ),
              _ActionButton(
                icon: Icons.favorite,
                color: OTheme.neonPink,
                onPressed: () => _matchEngine!.currentItem?.like(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwipeCard extends StatelessWidget {
  final Profile profile;

  const _SwipeCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: profile.avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(profile.avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
        color: OTheme.deepCharcoal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (profile.avatarUrl == null)
            const Center(
              child: Icon(Icons.person, size: 120, color: OTheme.neonPink),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${profile.displayName}, ${profile.age}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: OTheme.neonPink),
                    const SizedBox(width: 4),
                    const Text(
                      "Nearby",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      profile.pronouns ?? "",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (profile.bio != null)
                  Text(
                    profile.bio!,
                    style: const TextStyle(color: Colors.white60, fontSize: 16),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (profile.interests ?? []).take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        interest,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmall;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: OTheme.black,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: isSmall ? 24 : 32),
      ),
    );
  }
}
