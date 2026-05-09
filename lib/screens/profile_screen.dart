import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photos Grid
              SizedBox(
                width: 500,
                child: Column(
                  children: [
                    Container(
                      height: 500,
                      width: 500,
                      decoration: BoxDecoration(
                        color: OTheme.deepCharcoal,
                        borderRadius: BorderRadius.circular(24),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=80'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 20,
                            right: 20,
                            child: _Badge(label: 'Verified', color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SmallPhoto(url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80'),
                        _SmallPhoto(url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80'),
                        _SmallPhoto(url: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&q=80'),
                        _AddPhoto(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'David Sardarizadeh',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.verified, color: OTheme.neonPink, size: 32),
                      ],
                    ),
                    const Text(
                      '@davidsardar • He/Him • London',
                      style: TextStyle(color: OTheme.softRose, fontSize: 18),
                    ),
                    const SizedBox(height: 40),
                    _SectionTitle(title: 'About Me'),
                    const Text(
                      'Product designer and tech enthusiast. Building the future of queer social connection. Love techno, modern art, and good coffee.',
                      style: TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    _SectionTitle(title: 'Interests'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InterestTag(label: 'Techno'),
                        _InterestTag(label: 'Design'),
                        _InterestTag(label: 'Art'),
                        _InterestTag(label: 'Travel'),
                        _InterestTag(label: 'Coffee'),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _SectionTitle(title: 'Stats'),
                    const Row(
                      children: [
                        _StatItem(label: 'Vouches', value: '42'),
                        SizedBox(width: 40),
                        _StatItem(label: 'Connections', value: '156'),
                        SizedBox(width: 40),
                        _StatItem(label: 'Days Active', value: '89'),
                      ],
                    ),
                    const SizedBox(height: 60),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Edit Profile'),
                        ),
                        const SizedBox(width: 20),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white10),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          ),
                          child: const Text('Account Settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallPhoto extends StatelessWidget {
  final String url;
  const _SmallPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }
}

class _AddPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: OTheme.deepCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
      ),
      child: const Icon(Icons.add_a_photo_outlined, color: Colors.white24),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: OTheme.neonPink,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InterestTag extends StatelessWidget {
  final String label;
  const _InterestTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: OTheme.deepCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}
