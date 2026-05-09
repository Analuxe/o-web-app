import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'dart:async';

class MatchmakerScreen extends StatefulWidget {
  const MatchmakerScreen({super.key});

  @override
  State<MatchmakerScreen> createState() => _MatchmakerScreenState();
}

class _MatchmakerScreenState extends State<MatchmakerScreen> {
  bool isSearching = false;
  bool matchFound = false;

  void startSearch() {
    setState(() {
      isSearching = true;
      matchFound = false;
    });

    // Simulate search delay
    Timer(const Duration(seconds: 3), () {
      setState(() {
        isSearching = false;
        matchFound = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSearching && !matchFound) _buildInitialState(),
            if (isSearching) _buildSearchingState(),
            if (matchFound) _buildMatchFoundState(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distance Range', style: TextStyle(color: OTheme.softRose)),
                  Text('25 miles', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(value: 0.5, onChanged: (v) {}, activeColor: OTheme.neonPink),
              const SizedBox(height: 24),
              const Text('Intents', style: TextStyle(color: OTheme.softRose)),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                children: [
                  _Chip(label: 'Singles', isSelected: true),
                  _Chip(label: 'Hookups', isSelected: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: startSearch,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(300, 60),
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

  Widget _buildMatchFoundState() {
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
            const _UserCircle(url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: const Icon(Icons.favorite, color: OTheme.neonPink, size: 48),
            ),
            const _UserCircle(url: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80'),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'Fabian, 26',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Shared: Techno, Brunch, Nightlife',
          style: TextStyle(color: OTheme.softRose),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Confirm Date'),
            ),
            const SizedBox(width: 24),
            OutlinedButton(
              onPressed: () => setState(() => matchFound = false),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
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
  const _Chip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? OTheme.neonPink.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? OTheme.neonPink : Colors.white10),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? OTheme.neonPink : Colors.white54)),
    );
  }
}

class _UserCircle extends StatelessWidget {
  final String url;
  const _UserCircle({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: OTheme.neonPink, width: 3),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}
