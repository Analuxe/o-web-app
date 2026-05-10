import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:o_web/screens/discovery_swipe_tab.dart';
import 'package:geolocator/geolocator.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  Profile? _myProfile;
  bool _isLoadingMyProfile = true;
  TabController? _tabController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyProfile();
    _determinePosition();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMyProfile() async {
    final profile = await SupabaseService.getMyProfile();
    if (mounted) {
      setState(() {
        _myProfile = profile;
        _isLoadingMyProfile = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: OTheme.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: const [
              FilterSidebar(isDrawer: true),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1609.34;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 1200;

    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discovery',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: width < 600 ? 28 : 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: OTheme.neonPink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: OTheme.neonPink.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: OTheme.neonPink),
                                const SizedBox(width: 6),
                                Text(
                                  _currentPosition != null ? "Vines within 50 miles" : "Scanning location...",
                                  style: const TextStyle(color: OTheme.neonPink, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isLargeScreen)
                        IconButton(
                          onPressed: _showFilterSheet,
                          icon: const Icon(Icons.tune, color: OTheme.neonPink),
                          style: IconButton.styleFrom(
                            backgroundColor: OTheme.neonPink.withOpacity(0.1),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // TabBar Section
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
                        Tab(text: 'GRID VIEW'),
                        Tab(text: 'SWIPE MODE'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Content Section
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: SupabaseService.getNearbyVines(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
                        }
                        if (!snapshot.hasData || (_isLoadingLocation && _currentPosition == null)) {
                          return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
                        }
                        
                        var profiles = snapshot.data!
                            .map((json) => Profile.fromJson(json))
                            .where((p) => p.id != SupabaseService.client.auth.currentUser?.id)
                            .toList();

                        if (_currentPosition != null) {
                          profiles = profiles.where((p) {
                            if (p.latitude == null || p.longitude == null) return false;
                            final distance = _calculateDistance(p.latitude!, p.longitude!);
                            return distance <= 50;
                          }).toList();
                        }

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            // Grid Tab
                            profiles.isEmpty 
                              ? _buildEmptyState("No vines nearby.")
                              : GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: width < 600 ? 200 : 300,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: width < 600 ? 12 : 24,
                                    mainAxisSpacing: width < 600 ? 12 : 24,
                                  ),
                                  itemCount: profiles.length,
                                  itemBuilder: (context, index) => UserCard(
                                    profile: profiles[index],
                                    isCurrentUserVerified: _myProfile?.isVerified ?? false,
                                  ),
                                ),
                            // Swipe Tab
                            profiles.isEmpty
                              ? _buildEmptyState("No more vines to swipe.")
                              : DiscoverySwipeTab(
                                  profiles: profiles,
                                  isCurrentUserVerified: _myProfile?.isVerified ?? false,
                                ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLargeScreen) const FilterSidebar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}

class FilterSidebar extends StatelessWidget {
  final bool isDrawer;
  const FilterSidebar({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? null : 320,
      decoration: BoxDecoration(
        color: OTheme.black,
        border: isDrawer ? null : Border(
          left: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      padding: isDrawer ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (isDrawer)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
            ],
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
            children: const [
              _FilterChip(label: 'Gay', isSelected: true),
              _FilterChip(label: 'Bi', isSelected: false),
              _FilterChip(label: 'Trans', isSelected: false),
              _FilterChip(label: 'Queer', isSelected: true),
              _FilterChip(label: 'Non-binary', isSelected: false),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              if (isDrawer) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  final bool isCurrentUserVerified;
  const UserCard({super.key, required this.profile, this.isCurrentUserVerified = false});

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

  void _handleThumbsDown() async {
    if (!widget.isCurrentUserVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only verified accounts can cast a Thumbs Down.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    try {
      await SupabaseService.submitThumbsDown(widget.profile.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reputation report submitted.'), backgroundColor: OTheme.neonPink),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already reported this user.'), backgroundColor: Colors.white24),
        );
      }
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
          if (widget.isCurrentUserVerified)
            Positioned(
              top: 12,
              left: 12,
              child: InkWell(
                onTap: _handleThumbsDown,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.thumb_down_alt_outlined,
                    color: Colors.white54,
                    size: 16,
                  ),
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
