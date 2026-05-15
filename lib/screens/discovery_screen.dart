import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';

import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/models/discovery_filters.dart';
import 'package:o_web/widgets/filter_sidebar.dart';
import 'package:o_web/widgets/report_dialog.dart';
import 'package:o_web/models/tags.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  Profile? _myProfile;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  DiscoveryFilters _filters = DiscoveryFilters();

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
    _determinePosition();
  }

  Future<void> _loadMyProfile() async {
    final profile = await SupabaseService.getMyProfile();
    if (mounted) {
      setState(() {
        _myProfile = profile;
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
            children: [
              FilterSidebar(
                isDrawer: true,
                filters: _filters,
                onChanged: (newFilters) {
                  setState(() => _filters = newFilters);
                },
              ),
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
                              color: OTheme.neonPink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: OTheme.neonPink.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: OTheme.neonPink),
                                const SizedBox(width: 6),
                                Text(
                                  _currentPosition != null ? "Vines within ${_filters.maxDistance.toInt()} miles" : "Scanning location...",
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
                            backgroundColor: OTheme.neonPink.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                    ],
                  ),

                  
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

                        // APPLY FILTERS
                        profiles = profiles.where((p) {
                          // 1. Distance Filter
                          if (_currentPosition != null) {
                            if (p.latitude == null || p.longitude == null) return false;
                            final distance = _calculateDistance(p.latitude!, p.longitude!);
                            if (distance > _filters.maxDistance) return false;
                          }

                          // 2. Age Filter
                          if (p.age != null) {
                            if (p.age! < _filters.ageRange.start || p.age! > _filters.ageRange.end) return false;
                          }

                          // 3. Kink Filter
                          if (_filters.selectedKinks.isNotEmpty) {
                            final profileKinks = (p.labels ?? []).map((l) => l.split(':')[0]).toSet();
                            final matchesKink = _filters.selectedKinks.any((k) => profileKinks.contains(k));
                            if (!matchesKink) return false;
                          }

                          // 4. Role Filter
                          if (_filters.selectedRoles.isNotEmpty) {
                            final profileRoles = (p.labels ?? []).map((l) {
                              final parts = l.split(':');
                              if (parts.length < 2) return '';
                              final pref = int.tryParse(parts[1]) ?? 1;
                              return pref == 0 ? 'Bottom' : (pref == 1 ? 'Versatile' : 'Top');
                            }).toSet();
                            final matchesRole = _filters.selectedRoles.any((r) => profileRoles.contains(r));
                            if (!matchesRole) return false;
                          }

                          return true;
                        }).toList();

                        if (profiles.isEmpty) {
                          return _buildEmptyState("No vines match your filters.");
                        }

                        return GridView.builder(
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
                            canMessageAnyone: _myProfile?.canMessageAnyone ?? false,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLargeScreen) FilterSidebar(
            filters: _filters,
            onChanged: (newFilters) {
              setState(() => _filters = newFilters);
            },
          ),
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

class UserCard extends StatefulWidget {
  final Profile profile;
  final bool isCurrentUserVerified;
  final bool canMessageAnyone;
  const UserCard({
    super.key, 
    required this.profile, 
    this.isCurrentUserVerified = false,
    this.canMessageAnyone = false,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isExtended = false;
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

  void _handleBlock() async {
    await SupabaseService.blockUser(widget.profile.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Blocked'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _handleReport() {
    showReportDialog(context, reportedUserId: widget.profile.id);
  }

  void _handleProfile() {
    context.go('/profile?id=${widget.profile.id}');
  }

  void _handleMessage() {
    context.go('/messaging?id=${widget.profile.id}');
  }

  void _handleExtend() async {
    setState(() => _isExtended = true);
    await SupabaseService.extendVine(widget.profile.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Match Request Sent to ${widget.profile.displayName}!'),
              const SizedBox(height: 4),
              const Text(
                'Note: Recipients are instructed to only allow requests if they are interested.',
                style: TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: OTheme.neonPink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
    return InkWell(
      onTap: _handleProfile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: OTheme.deepCharcoal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isExtended ? OTheme.neonPink.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
            width: _isExtended ? 2 : 1,
          ),
          boxShadow: _isExtended ? [
            BoxShadow(color: OTheme.neonPink.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5),
          ] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final photos = _allPhotos;
                      final currentPhotoUrl = photos.isNotEmpty ? photos[_currentPhotoIndex] : null;

                      return GestureDetector(
                        onTapUp: (details) => _handlePhotoTap(details, constraints.maxWidth),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: currentPhotoUrl != null 
                                  ? DecorationImage(image: NetworkImage(currentPhotoUrl), fit: BoxFit.cover)
                                  : null,
                                gradient: currentPhotoUrl == null ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    OTheme.neonPink.withValues(alpha: 0.2),
                                    OTheme.black.withValues(alpha: 0.8),
                                  ],
                                ) : null,
                              ),
                              child: currentPhotoUrl == null ? const Icon(
                                Icons.person,
                                size: 64,
                                color: OTheme.neonPink,
                              ) : null,
                            ),
                            if (photos.length > 1)
                              Positioned(
                                top: 8,
                                left: 8,
                                right: 8,
                                child: Row(
                                  children: List.generate(
                                    photos.length,
                                    (index) => Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        height: 3,
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
                          ],
                        ),
                      );
                    }
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
                            child: Row(
                              children: [
                                Flexible(
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
                                if (widget.profile.isOnline)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.greenAccent, blurRadius: 4, spreadRadius: 1),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
                            color: OTheme.deepCharcoal,
                            onSelected: (value) {
                              if (value == 'block') {
                                _handleBlock();
                              } else if (value == 'report') {
                                _handleReport();
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
                        children: (widget.profile.interests ?? []).take(2).map((i) => _Tag(label: UserTag.format(i))).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: widget.canMessageAnyone 
                ? FloatingActionButton.small(
                    onPressed: _handleMessage,
                    backgroundColor: OTheme.neonPink,
                    child: const Icon(Icons.message, color: Colors.black),
                  )
                : FloatingActionButton.small(
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
                      color: Colors.black.withValues(alpha: 0.6),
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
        color: OTheme.neonPink.withValues(alpha: 0.1),
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
