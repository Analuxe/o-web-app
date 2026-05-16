import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';

class DiscoverySwipeTab extends StatefulWidget {
  final List<Profile> profiles;
  final Profile? myProfile;
  final bool isCurrentUserVerified;
  final bool canMessageAnyone;

  const DiscoverySwipeTab({
    super.key,
    required this.profiles,
    this.myProfile,
    this.isCurrentUserVerified = false,
    this.canMessageAnyone = false,
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
            // RIGHT SWIPE - Send match or message
            if (widget.canMessageAnyone) {
              context.go('/messaging?id=${profile.id}');
            } else {
              SupabaseService.extendVine(profile.id);
              SupabaseService.notifyMatchRequest(profile.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Match Request Sent to ${profile.displayName}!"),
                  backgroundColor: OTheme.neonPink,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          nopeAction: () {
            // LEFT SWIPE - Skip and remove from flow
            SupabaseService.skipUser(profile.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${profile.displayName} removed from your flow."),
                backgroundColor: Colors.white24,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          superlikeAction: () {
             SupabaseService.extendVine(profile.id);
             SupabaseService.notifyMatchRequest(profile.id);
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

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: MediaQuery.of(context).size.height * 0.65 < 450 ? 450 : MediaQuery.of(context).size.height * 0.65,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24, 
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: SwipeCards(
                    matchEngine: _matchEngine!,
                    itemBuilder: (BuildContext context, int index) {
                      final profile = _swipeItems[index].content as Profile;
                      return _SwipeCard(profile: profile, myProfile: widget.myProfile);
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
            ),
          ),
        Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
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
                onPressed: () => _matchEngine!.currentItem?.like(),
                isSmall: true,
              ),
              _ActionButton(
                icon: widget.canMessageAnyone ? Icons.message : Icons.favorite,
                color: OTheme.neonPink,
                onPressed: () => _matchEngine!.currentItem?.like(),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

class _SwipeCard extends StatefulWidget {
  final Profile profile;
  final Profile? myProfile;

  const _SwipeCard({required this.profile, this.myProfile});

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  int _currentPhotoIndex = 0;

  List<String> get _allPhotos {
    final photos = <String>[];
    if (widget.profile.avatarUrl != null) photos.add(widget.profile.avatarUrl!);
    if (widget.profile.galleryUrls != null) photos.addAll(widget.profile.galleryUrls!);
    return photos;
  }

  void _handlePhotoTap(TapUpDetails details, double width) {
    final photos = _allPhotos;
    if (photos.length <= 1) return;

    if (details.localPosition.dx < width / 2) {
      if (_currentPhotoIndex > 0) {
        setState(() => _currentPhotoIndex--);
      }
    } else {
      if (_currentPhotoIndex < photos.length - 1) {
        setState(() => _currentPhotoIndex++);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final photos = _allPhotos;
    final currentPhotoUrl = photos.isNotEmpty ? photos[_currentPhotoIndex] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            // Only switch photos if tapping the upper 70% of the card
            if (details.localPosition.dy < constraints.maxHeight * 0.7) {
              _handlePhotoTap(details, constraints.maxWidth);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: currentPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(currentPhotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: OTheme.deepCharcoal,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (currentPhotoUrl == null)
                  const Center(
                    child: Icon(Icons.person, size: 120, color: OTheme.neonPink),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
                if (photos.length > 1)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: List.generate(
                        photos.length,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index == _currentPhotoIndex 
                                ? Colors.white 
                                : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Compatibility Score Badge
                if (widget.myProfile != null)
                  Builder(
                    builder: (context) {
                      final rawScore = widget.myProfile!.getCompatibilityScore(profile);
                      if (rawScore <= 0) return const SizedBox.shrink();
                      
                      final percent = (rawScore.clamp(0, 100)) / 100.0;
                      final displayScore = (percent * 100).round();
                      
                      final Color scoreColor;
                      if (displayScore >= 70) {
                        scoreColor = const Color(0xFFFFD700);
                      } else if (displayScore >= 40) {
                        scoreColor = OTheme.neonPink;
                      } else {
                        scoreColor = Colors.white54;
                      }

                      return Positioned(
                        top: 32,
                        right: 16,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.7),
                            boxShadow: displayScore >= 40 ? [
                              BoxShadow(
                                color: scoreColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ] : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: percent,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                                ),
                              ),
                              Text(
                                '$displayScore',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "${profile.displayName}, ${profile.age}",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isOnline)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.greenAccent, blurRadius: 6, spreadRadius: 2),
                          ],
                        ),
                      ),
                  ],
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
                        color: Colors.white.withValues(alpha: 0.1),
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
          ),
        ],
      ),
    ),
    );
    },
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
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
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
