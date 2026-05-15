import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:o_web/screens/discovery_swipe_tab.dart';

class MatchmakerScreen extends StatefulWidget {
  const MatchmakerScreen({super.key});

  @override
  State<MatchmakerScreen> createState() => _MatchmakerScreenState();
}

class _MatchmakerScreenState extends State<MatchmakerScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool isSearching = false;
  Profile? myProfile;
  Profile? matchedProfile;
  int matchScore = 0;
  int distanceRange = 25;
  List<String> selectedIntents = ['Singles', 'Hookups'];
  bool isLoadingSettings = true;
  bool isConfirming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      myProfile = await SupabaseService.getMyProfile();
      final optIn = await SupabaseService.getMatchmakerOptIn();
      if (optIn != null && mounted) {
        setState(() {
          distanceRange = optIn['max_distance'] ?? 25;
          selectedIntents = List<String>.from(optIn['intents'] ?? ['Singles', 'Hookups']);
        });
      }
    } catch (e) {
      debugPrint('Error loading matchmaker settings: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingSettings = false);
      }
    }
  }

  void _toggleIntent(String intent) {
    setState(() {
      if (selectedIntents.contains(intent)) {
        selectedIntents.remove(intent);
      } else {
        selectedIntents.add(intent);
      }
    });
  }

  Future<void> startSearch() async {
    setState(() {
      isSearching = true;
      matchedProfile = null;
    });

    try {
      // Save settings first
      await SupabaseService.saveMatchmakerOptIn(distanceRange, selectedIntents);
      
      // Simulate scanning animation delay
      await Future.delayed(const Duration(seconds: 2));

      // Find candidates
      final candidates = await SupabaseService.findMatchmakerCandidates(distanceRange, selectedIntents);
      
      if (mounted) {
        setState(() {
          isSearching = false;
          if (candidates.isNotEmpty) {
            // Pick a random candidate for the "Match" experience
            matchedProfile = candidates[Random().nextInt(candidates.length)];
            if (myProfile != null) {
              matchScore = myProfile!.getCompatibilityScore(matchedProfile!);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error finding matches: $e');
      if (mounted) {
        setState(() => isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matchmaker error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _handleConfirmDate() async {
    if (matchedProfile == null) return;
    
    setState(() => isConfirming = true);
    try {
      const proposal = '🐷 O Admin Proposal: How about meeting up on Friday at 8:00 PM? No pressure — just good energy.';
      await SupabaseService.sendProposal(matchedProfile!.id, proposal);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal sent! Check your messages to coordinate.'),
            backgroundColor: OTheme.neonPink,
          ),
        );
        setState(() => matchedProfile = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending proposal: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matchmaker',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: width < 600 ? 28 : 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: OTheme.neonPink,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white24,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'O ADMIN MATCH'),
                  Tab(text: 'SWIPE MODE'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMatchmakerContent(isMobile),
                  _buildSwipeTab(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchmakerContent(bool isMobile) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoadingSettings) const Center(child: CircularProgressIndicator(color: OTheme.neonPink)),
              if (!isLoadingSettings && !isSearching && matchedProfile == null) _buildInitialState(isMobile),
              if (isSearching) _buildSearchingState(),
              if (matchedProfile != null) _buildMatchFoundState(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeTab(bool isMobile) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getNearbyVines(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
        }
        
        var profiles = snapshot.data!
            .map((json) => Profile.fromJson(json))
            .where((p) => p.id != SupabaseService.client.auth.currentUser?.id)
            .toList();

        if (profiles.isEmpty) {
          return const Center(child: Text("No more vines to swipe.", style: TextStyle(color: Colors.white24, fontSize: 16)));
        }

        return DiscoverySwipeTab(
          profiles: profiles,
          isCurrentUserVerified: myProfile?.isVerified ?? false,
          canMessageAnyone: myProfile?.canMessageAnyone ?? false,
        );
      },
    );
  }

  Widget _buildInitialState(bool isMobile) {
    return Column(
      children: [
        const Icon(Icons.auto_awesome, size: 80, color: OTheme.neonPink),
        const SizedBox(height: 32),
        Text(
          'O Matchmaker',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        const Text(
          'Let the "O Admin" find your next connection. We use shared interests and proximity to suggest a perfect date.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: OTheme.deepCharcoal,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Search Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Distance Range', style: TextStyle(color: OTheme.softRose)),
                  Text('$distanceRange miles', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: distanceRange.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                onChanged: (v) => setState(() => distanceRange = v.round()),
                activeColor: OTheme.neonPink,
              ),
              const SizedBox(height: 24),
              const Text('Intents', style: TextStyle(color: OTheme.softRose)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  _Chip(
                    label: 'Singles', 
                    isSelected: selectedIntents.contains('Singles'),
                    onTap: () => _toggleIntent('Singles'),
                  ),
                  _Chip(
                    label: 'Hookups', 
                    isSelected: selectedIntents.contains('Hookups'),
                    onTap: () => _toggleIntent('Hookups'),
                  ),
                  _Chip(
                    label: 'Friends', 
                    isSelected: selectedIntents.contains('Friends'),
                    onTap: () => _toggleIntent('Friends'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: startSearch,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(isMobile ? double.infinity : 300, 60),
          ),
          child: const Text('Find My Vibe'),
        ),
      ],
    );
  }

  Widget _buildSearchingState() {
    return const Column(
      children: [
        CircularProgressIndicator(color: OTheme.neonPink, strokeWidth: 8),
        SizedBox(height: 48),
        Text(
          'Scanning the Signal...',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          'Comparing interests, location, and vibes.',
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildMatchFoundState(bool isMobile) {
    return Column(
      children: [
        const Text(
          "It's a Match!",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: OTheme.neonPink),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: OTheme.neonPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OTheme.neonPink),
          ),
          child: Text(
            '${min(99, 60 + matchScore)}% MATCH',
            style: const TextStyle(color: OTheme.neonPink, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _UserCircle(
              url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80',
              size: isMobile ? 80 : 120,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
              child: Icon(Icons.favorite, color: OTheme.neonPink, size: isMobile ? 32 : 48),
            ),
            _UserCircle(
              url: matchedProfile?.avatarUrl ?? 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
              size: isMobile ? 80 : 120,
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          '${matchedProfile?.displayName ?? 'Anonymous'}, ${matchedProfile?.age ?? '??'}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Shared Interests: ${matchedProfile?.interests?.join(', ') ?? 'Vibes'}',
          style: const TextStyle(color: OTheme.softRose),
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OTheme.neonPink.withOpacity(0.2)),
          ),
          child: const Column(
            children: [
              Text(
                '🐷 O Admin Proposal',
                style: TextStyle(fontWeight: FontWeight.bold, color: OTheme.neonPink),
              ),
              SizedBox(height: 12),
              Text(
                'How about meeting up on Friday (5/12) at 8:00 PM?\nNo pressure — just good energy.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isConfirming ? null : _handleConfirmDate,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(isMobile ? double.infinity : 200, 56),
              ),
              child: isConfirming 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Confirm Date'),
            ),
            if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 24),
            OutlinedButton(
              onPressed: () => setState(() => matchedProfile = null),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                minimumSize: Size(isMobile ? double.infinity : 200, 56),
              ),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? OTheme.neonPink.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? OTheme.neonPink : Colors.white10),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? OTheme.neonPink : Colors.white54)),
      ),
    );
  }
}

class _UserCircle extends StatelessWidget {
  final String url;
  final double size;
  const _UserCircle({required this.url, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: OTheme.neonPink, width: 3),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}
