import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'dart:async';
import 'dart:math';

class MatchmakerScreen extends StatefulWidget {
  const MatchmakerScreen({super.key});

  @override
  State<MatchmakerScreen> createState() => _MatchmakerScreenState();
}

class _MatchmakerScreenState extends State<MatchmakerScreen> {
  bool isSearching = false;
  Profile? matchedProfile;
  int distanceRange = 25;
  List<String> selectedIntents = ['Singles', 'Hookups'];
  bool isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

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
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(isMobile ? double.infinity : 200, 56),
              ),
              child: const Text('Confirm Date'),
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
