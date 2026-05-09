import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Vines',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return const UserCard();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const FilterSidebar(),
      ],
    );
  }
}

class FilterSidebar extends StatelessWidget {
  const FilterSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: OTheme.black,
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const _FilterLabel(label: 'Distance'),
          Slider(
            value: 0.5,
            onChanged: (v) {},
            activeColor: OTheme.neonPink,
            inactiveColor: Colors.white10,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.1 mi', style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('50 mi', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),
          const _FilterLabel(label: 'Age Range'),
          RangeSlider(
            values: const RangeValues(18, 45),
            min: 18,
            max: 99,
            onChanged: (v) {},
            activeColor: OTheme.neonPink,
          ),
          const SizedBox(height: 32),
          const _FilterLabel(label: 'Identity Labels'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(label: 'Gay', isSelected: true),
              _FilterChip(label: 'Bi', isSelected: false),
              _FilterChip(label: 'Trans', isSelected: false),
              _FilterChip(label: 'Queer', isSelected: true),
              _FilterChip(label: 'Non-binary', isSelected: false),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.white38,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String label;
  const _FilterLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: OTheme.softRose,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? OTheme.neonPink.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? OTheme.neonPink : Colors.white10,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? OTheme.neonPink : Colors.white54,
          fontSize: 12,
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OTheme.deepCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OTheme.neonPink.withOpacity(0.2),
                    OTheme.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 64,
                color: OTheme.neonPink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Alex, 24',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'He/Him • 0.5 miles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _Tag(label: 'Design'),
                    _Tag(label: 'Music'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OTheme.neonPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: OTheme.neonPink,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
