import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
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
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: SupabaseService.getNearbyVines(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
                      
                      final profiles = snapshot.data!
                          .map((json) => Profile.fromJson(json))
                          .where((p) => p.id != SupabaseService.client.auth.currentUser?.id)
                          .toList();

                      if (profiles.isEmpty) {
                        return const Center(child: Text('No vines nearby yet.', style: TextStyle(color: Colors.white24)));
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          return UserCard(profile: profiles[index]);
                        },
                      );
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

class UserCard extends StatefulWidget {
  final Profile profile;
  const UserCard({super.key, required this.profile});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isExtended = false;

  void _handleBlock() async {
    await SupabaseService.blockUser(widget.profile.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Blocked'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OTheme.deepCharcoal,
        title: const Text('Report Profile', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for reporting...',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.reportUser(widget.profile.id, reasonController.text, '');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report Submitted'), backgroundColor: OTheme.neonPink),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _handleExtend() async {
    setState(() => _isExtended = true);
    await SupabaseService.extendVine(widget.profile.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vine Extended to ${widget.profile.displayName}!'),
          backgroundColor: OTheme.neonPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OTheme.deepCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExtended ? OTheme.neonPink.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: _isExtended ? 2 : 1,
        ),
        boxShadow: _isExtended ? [
          BoxShadow(color: OTheme.neonPink.withOpacity(0.2), blurRadius: 20, spreadRadius: -5),
        ] : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: widget.profile.avatarUrl != null 
                      ? DecorationImage(image: NetworkImage(widget.profile.avatarUrl!), fit: BoxFit.cover)
                      : null,
                    gradient: widget.profile.avatarUrl == null ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OTheme.neonPink.withOpacity(0.2),
                        OTheme.black.withOpacity(0.8),
                      ],
                    ) : null,
                  ),
                  child: widget.profile.avatarUrl == null ? const Icon(
                    Icons.person,
                    size: 64,
                    color: OTheme.neonPink,
                  ) : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.profile.displayName}, ${widget.profile.age}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
                          color: OTheme.deepCharcoal,
                          onSelected: (value) {
                            if (value == 'block') {
                              _handleBlock();
                            } else if (value == 'report') {
                              _showReportDialog();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'report', child: Text('Report Profile', style: TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'block', child: Text('Block User', style: TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.profile.pronouns} • Nearby',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: (widget.profile.interests ?? []).take(2).map((i) => _Tag(label: i)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              onPressed: _isExtended ? null : _handleExtend,
              backgroundColor: _isExtended ? Colors.grey : OTheme.neonPink,
              child: Icon(
                _isExtended ? Icons.check : Icons.add,
                color: Colors.black,
              ),
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
