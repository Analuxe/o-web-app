import 'package:o_web/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:o_web/screens/verification_screen.dart';
import 'package:o_web/widgets/tag_selector.dart';
import 'package:o_web/models/tags.dart';
import 'package:o_web/widgets/report_dialog.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _zipcodeController = TextEditingController();
  String? _selectedPronouns;
  String? _selectedRelationshipStatus;
  List<String> _selectedInterests = [];
  List<String> _galleryUrls = [];
  final Map<String, TextEditingController> _promptControllers = {};
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  bool _isUploading = false;
  int _currentPhotoIndex = 0;

  List<Map<String, dynamic>> _endorsements = [];
  bool _hasEndorsed = false;

  List<String> get _allPhotos {
    final photos = <String>[];
    if (_profile?.avatarUrl != null) photos.add(_profile!.avatarUrl!);
    photos.addAll(_galleryUrls);
    return photos;
  }

  void _handlePhotoTap(TapUpDetails details, double width) {
    final photos = _allPhotos;
    if (photos.length <= 1) return;

    setState(() {
      if (details.localPosition.dx > width / 2) {
        _currentPhotoIndex = (_currentPhotoIndex + 1) % photos.length;
      } else {
        _currentPhotoIndex = (_currentPhotoIndex - 1 + photos.length) % photos.length;
      }
    });
  }

  void _showVisitorsDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OTheme.deepCharcoal,
        title: const Text('Recent Visitors', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          height: 500,
          child: FutureBuilder<List<Profile>>(
            future: SupabaseService.getProfileViewers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
              }
              final viewers = snapshot.data ?? [];
              if (viewers.isEmpty) {
                return const Center(child: Text('No recent visitors yet.', style: TextStyle(color: Colors.white54)));
              }
              return ListView.builder(
                itemCount: viewers.length,
                itemBuilder: (context, index) {
                  final viewer = viewers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: viewer.avatarUrl != null ? NetworkImage(viewer.avatarUrl!) : null,
                      backgroundColor: OTheme.neonPink.withValues(alpha: 0.1),
                      child: viewer.avatarUrl == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
                    ),
                    title: Text(viewer.displayName ?? 'User', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('@${viewer.username ?? 'user'}', style: const TextStyle(color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/${viewer.id}');
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }


  void _showEndorseDialog() {
    final controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: OTheme.deepCharcoal,
          title: Text('Endorse ${_profile?.displayName ?? 'User'}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Write a short vouch for this user. This will be visible on their profile after they approve it.', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Great connection, very respectful...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: OTheme.black,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (controller.text.trim().isEmpty) return;
                setDialogState(() => isSubmitting = true);
                try {
                  await SupabaseService.createEndorsement(widget.userId!, controller.text.trim());
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endorsement request sent!')));
                  setState(() => _hasEndorsed = true);
                } catch (e) {
                  safeLog('Error endorsing: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: OTheme.neonPink),
              child: isSubmitting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Submit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final String? myId = SupabaseService.client.auth.currentUser?.id;
      final bool isMe = widget.userId == null || widget.userId == myId;

      final profile = isMe 
          ? await SupabaseService.getMyProfile() 
          : await SupabaseService.getProfile(widget.userId!);

      if (!isMe && widget.userId != null) {
        SupabaseService.logProfileView(widget.userId!);
      }

      final endorsements = await SupabaseService.getEndorsements(profile?.id ?? myId!);
      bool hasEndorsed = false;
      if (!isMe && widget.userId != null) {
        hasEndorsed = await SupabaseService.hasEndorsed(widget.userId!);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          if (profile != null) {
            _galleryUrls = List.from(profile.galleryUrls ?? []);
            if (isMe) {
              _displayNameController.text = profile.displayName ?? '';
              _bioController.text = profile.bio ?? '';
              _zipcodeController.text = profile.zipcode ?? '';
              _selectedPronouns = profile.pronouns;
              _selectedRelationshipStatus = profile.relationshipStatus;
              _selectedInterests = List.from(profile.interests ?? []);

              final prompts = profile.prompts ?? {};
              for (final key in prompts.keys) {
                _promptControllers[key] = TextEditingController(text: prompts[key]);
              }

              final socialLinks = profile.socialLinks ?? {};
              _instagramController.text = socialLinks['instagram'] ?? '';
              _twitterController.text = socialLinks['x'] ?? '';
            }
          }
          _endorsements = endorsements;
          _hasEndorsed = hasEndorsed;
        });
      }
    } catch (e) {
      safeLog('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_zipcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zipcode is mandatory')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> prompts = {};
      _promptControllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          prompts[key] = controller.text.trim();
        }
      });

      final Map<String, dynamic> socialLinks = {};
      if (_instagramController.text.trim().isNotEmpty) socialLinks['instagram'] = _instagramController.text.trim();
      if (_twitterController.text.trim().isNotEmpty) socialLinks['x'] = _twitterController.text.trim();

      final fullData = {
        'display_name': _displayNameController.text.isEmpty ? null : _displayNameController.text,
        'bio': _bioController.text.isEmpty ? null : _bioController.text,
        'zipcode': _zipcodeController.text.trim(),
        'pronouns': _selectedPronouns,
        'relationship_status': _selectedRelationshipStatus,
        'interests': _selectedInterests,
        'gallery_urls': _galleryUrls,
        'prompts': prompts,
        'social_links': socialLinks,
      };

      await SupabaseService.updateProfile(fullData);
      
      await _loadProfile();
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      safeLog('Save Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final userId = SupabaseService.client.auth.currentUser?.id;
        
        if (userId != null) {
          final url = await SupabaseService.uploadAvatar(userId, bytes, fileName);
          await SupabaseService.updateProfile({'avatar_url': url});
          await _loadProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_galleryUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 6 photos allowed')));
      return;
    }
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final userId = SupabaseService.client.auth.currentUser?.id;
        
        if (userId != null) {
          final url = await SupabaseService.uploadGalleryImage(userId, bytes, fileName);
          setState(() {
            _galleryUrls.add(url);
          });
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryUrls.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        backgroundColor: OTheme.black,
        body: Center(child: CircularProgressIndicator(color: OTheme.neonPink)),
      );
    }

    final String? myId = SupabaseService.client.auth.currentUser?.id;
    final bool isMe = widget.userId == null || widget.userId == myId;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: OTheme.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  isMe ? 'My Profile' : (_profile?.displayName ?? 'Profile'), 
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: isMobile ? 28 : 32)
                ),
              if (isMe) ...[
                if (!_isEditing)
                  Padding(
                    padding: EdgeInsets.only(top: isMobile ? 16 : 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profile'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _showVisitorsDialog,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Visitors'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white10),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(top: isMobile ? 16 : 0),
                    child: Row(
                      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        if (isMobile) const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                              ) 
                            : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                // Actions for other user's profile
                Row(
                  children: [
                    IconButton(
                      onPressed: () => showReportDialog(context, reportedUserId: widget.userId!),
                      icon: const Icon(Icons.report_problem_outlined, color: Colors.white24),
                      tooltip: 'Report User',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/messaging?id=${widget.userId}'),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OTheme.neonPink,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _hasEndorsed ? null : _showEndorseDialog,
                      icon: Icon(_hasEndorsed ? Icons.how_to_reg : Icons.thumb_up_alt_outlined, size: 18),
                      label: Text(_hasEndorsed ? 'Pending/Endorsed' : 'Endorse'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasEndorsed ? Colors.white24 : OTheme.neonPink.withValues(alpha: 0.1),
                        foregroundColor: _hasEndorsed ? Colors.white54 : OTheme.neonPink,
                        side: _hasEndorsed ? BorderSide.none : const BorderSide(color: OTheme.neonPink),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 40),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Carousel Header
              Center(
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final photos = _allPhotos;
                        return GestureDetector(
                          onTapUp: (details) => _handlePhotoTap(details, isMobile ? 140 : 180),
                          child: Stack(
                            children: [
                              Container(
                                width: isMobile ? 140 : 180,
                                height: isMobile ? 140 : 180,
                                decoration: BoxDecoration(
                                  color: OTheme.deepCharcoal,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white10),
                                  image: photos.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(photos[_currentPhotoIndex % photos.length]), 
                                          fit: BoxFit.cover
                                        )
                                      : null,
                                ),
                                child: _isUploading 
                                    ? const Center(child: CircularProgressIndicator(color: OTheme.neonPink))
                                    : (photos.isEmpty
                                        ? Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(isMobile ? 30 : 40.0),
                                              child: Image.asset(
                                                'assets/logo.png',
                                                color: OTheme.neonPink.withValues(alpha: 0.3),
                                              ),
                                            ),
                                          )
                                        : null),
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
                                          height: 2,
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: index == _currentPhotoIndex 
                                                ? OTheme.neonPink 
                                                : Colors.white24,
                                            borderRadius: BorderRadius.circular(1),
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
                    if (isMe) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickImage,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(_isUploading ? 'Uploading...' : 'Update Main Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OTheme.neonPink,
                          side: const BorderSide(color: OTheme.neonPink),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Images are moderated for safety.',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ],
                    if (_profile?.isVerified == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 14),
                            SizedBox(width: 6),
                            Text('Verified', style: TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                      ),
                    ] else if (isMe) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VerificationScreen()),
                        ),
                        icon: const Icon(Icons.verified_user, size: 16),
                        label: const Text('Get Verified'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OTheme.neonPink.withValues(alpha: 0.1),
                          foregroundColor: OTheme.neonPink,
                          side: const BorderSide(color: OTheme.neonPink),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isMobile) const SizedBox(width: 48) else const SizedBox(height: 48),
              // Info Column
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Name
                    _buildField(
                      label: 'Display Name',
                      value: _profile?.displayName ?? 'Not set',
                      controller: _displayNameController,
                      isEditing: _isEditing,
                    ),
                    const SizedBox(height: 24),
    
                    // Zipcode
                    _buildField(
                      label: 'Zipcode',
                      value: _profile?.zipcode ?? 'Mandatory',
                      controller: _zipcodeController,
                      isEditing: _isEditing,
                      hint: 'Required for matching',
                    ),
                    const SizedBox(height: 24),
                    
                    // Social Links
                    _buildLabel('Social Links'),
                    if (_isEditing) ...[
                      TextField(
                        controller: _instagramController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration().copyWith(hintText: 'Instagram Handle', prefixText: '@'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _twitterController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration().copyWith(hintText: 'X (Twitter) Handle', prefixText: '@'),
                      ),
                    ] else ...[
                      if (_profile?.socialLinks != null && _profile!.socialLinks!.isNotEmpty)
                        Row(
                          children: [
                            if (_profile!.socialLinks!['instagram'] != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text('IG: @${_profile!.socialLinks!['instagram']}', style: const TextStyle(color: OTheme.neonPink)),
                              ),
                            if (_profile!.socialLinks!['x'] != null)
                              Text('X: @${_profile!.socialLinks!['x']}', style: const TextStyle(color: OTheme.neonPink)),
                          ],
                        )
                      else
                        const Text('No social links', style: TextStyle(color: Colors.white24, fontSize: 16)),
                    ],
                    const SizedBox(height: 24),
    
                    // Pronouns
                    const SizedBox(height: 32),

                    // Photo Gallery
                    _buildLabel('Photo Gallery'),
                    if (_galleryUrls.isNotEmpty || _isEditing)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _isEditing ? (_galleryUrls.length < 6 ? _galleryUrls.length + 1 : 6) : _galleryUrls.length,
                        itemBuilder: (context, index) {
                          if (_isEditing && index == _galleryUrls.length) {
                            return InkWell(
                              onTap: _pickGalleryImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Icon(Icons.add_photo_alternate, color: Colors.white54, size: 32),
                              ),
                            );
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_galleryUrls[index], fit: BoxFit.cover),
                              ),
                              if (_isEditing)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () => _removeGalleryImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    else
                      const Text('No photos in gallery', style: TextStyle(color: Colors.white24, fontSize: 16)),

                    const SizedBox(height: 8),
                    const Text(
                      'All gallery photos are subject to automated moderation.',
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                    ),

                    const SizedBox(height: 32),
                    
                    _buildLabel('About'),
                    if (_isEditing)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPronouns,
                        dropdownColor: OTheme.deepCharcoal,
                        decoration: _inputDecoration(),
                        items: ['He/Him', 'She/Her', 'They/Them', 'Other'].map((p) =>
                          DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))
                        ).toList(),
                        onChanged: (val) => setState(() => _selectedPronouns = val),
                      )
                    else
                      Text(
                        _profile?.pronouns ?? 'Not set',
                        style: TextStyle(
                          color: _profile?.pronouns != null ? Colors.white : Colors.white24,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 24),
    
                    // Relationship Status
                    _buildLabel('Relationship Status'),
                    if (_isEditing)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRelationshipStatus,
                        dropdownColor: OTheme.deepCharcoal,
                        decoration: _inputDecoration(),
                        items: ['Single', 'LTR', 'Poly'].map((s) =>
                          DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))
                        ).toList(),
                        onChanged: (val) => setState(() => _selectedRelationshipStatus = val),
                      )
                    else
                      Text(
                        _profile?.relationshipStatus ?? 'Not set',
                        style: TextStyle(
                          color: _profile?.relationshipStatus != null ? Colors.white : Colors.white24,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 24),
    
                    // Bio
                    _buildField(
                      label: 'Bio',
                      value: _profile?.bio ?? 'Not set',
                      controller: _bioController,
                      isEditing: _isEditing,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
    
                    // Interests
                    _buildLabel('Interests'),
                    if (_isEditing)
                      CategorizedTagSelector(
                        selectedTags: _selectedInterests,
                        onChanged: (tags) {
                          setState(() {
                            _selectedInterests = tags;
                          });
                        },
                      )
                    else if (_profile?.interests?.isNotEmpty == true)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _profile!.interests!.map((i) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: OTheme.neonPink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: OTheme.neonPink.withValues(alpha: 0.3)),
                          ),
                          child: Text(UserTag.format(i), style: const TextStyle(color: OTheme.neonPink, fontSize: 13)),
                        )).toList(),
                      )
                    else
                      const Text('No interests set', style: TextStyle(color: Colors.white24, fontSize: 16)),
                      
                    const SizedBox(height: 32),
                    
                    // Prompts
                    _buildLabel('Icebreakers'),
                    if (_isEditing) ...[
                      _buildPromptEditor('My ideal night out involves...'),
                      const SizedBox(height: 12),
                      _buildPromptEditor('The most controversial opinion I have is...'),
                      const SizedBox(height: 12),
                      _buildPromptEditor('I am looking for...'),
                    ] else ...[
                      if (_profile?.prompts != null && _profile!.prompts!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _profile!.prompts!.entries.map((e) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key, style: const TextStyle(color: OTheme.softRose, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          )).toList(),
                        )
                      else
                        const Text('No icebreakers set', style: TextStyle(color: Colors.white24, fontSize: 16)),
                    ],
                    
                    const SizedBox(height: 32),

                    // Endorsements Section
                    _buildLabel('Community Vouches (${_endorsements.length})'),
                    if (_endorsements.isEmpty)
                      const Text('No public endorsements yet.', style: TextStyle(color: Colors.white24, fontSize: 16))
                    else
                      Column(
                        children: _endorsements.map((e) {
                          final endorser = e['endorser'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: endorser['avatar_url'] != null ? NetworkImage(endorser['avatar_url']) : null,
                                      backgroundColor: OTheme.deepCharcoal,
                                      child: endorser['avatar_url'] == null ? const Icon(Icons.person, size: 16, color: OTheme.neonPink) : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(endorser['display_name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    if (endorser['is_verified'] == true) const Icon(Icons.verified, size: 14, color: Colors.blue),
                                  ],
                                ),
                                if (e['content'] != null && e['content'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('"${e['content']}"', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(color: OTheme.softRose, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        if (isEditing)
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration().copyWith(hintText: hint),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: (value == 'Not set' || value == 'Mandatory') ? Colors.white24 : Colors.white,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildPromptEditor(String prompt) {
    if (!_promptControllers.containsKey(prompt)) {
      _promptControllers[prompt] = TextEditingController(text: _profile?.prompts?[prompt]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt, style: const TextStyle(color: OTheme.softRose, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _promptControllers[prompt],
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration().copyWith(hintText: 'Your answer...'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
