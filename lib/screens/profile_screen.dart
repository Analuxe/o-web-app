import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:o_web/screens/verification_screen.dart';
import 'dart:typed_data';
import 'package:o_web/widgets/tag_selector.dart';
import 'package:o_web/models/tags.dart';
import 'package:o_web/models/profile.dart';
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
  List<String> _selectedInterests = [];
  bool _isUploading = false;


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final String? myId = SupabaseService.client.auth.currentUser?.id;
    final bool isMe = widget.userId == null || widget.userId == myId;

    final profile = isMe 
        ? await SupabaseService.getMyProfile() 
        : await SupabaseService.getProfile(widget.userId!);

    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile != null && isMe) {
          _displayNameController.text = profile.displayName ?? '';
          _bioController.text = profile.bio ?? '';
          _zipcodeController.text = profile.zipcode ?? '';
          _selectedPronouns = profile.pronouns;
          _selectedInterests = List.from(profile.interests ?? []);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_zipcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zipcode is mandatory')));
      return;
    }

    setState(() => _isLoading = true);
    await SupabaseService.updateProfile({
      'display_name': _displayNameController.text.isEmpty ? null : _displayNameController.text,
      'bio': _bioController.text.isEmpty ? null : _bioController.text,
      'zipcode': _zipcodeController.text.trim(),
      'pronouns': _selectedPronouns,
      'interests': _selectedInterests,
    });
    await _loadProfile();
    setState(() => _isEditing = false);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    final String? myId = SupabaseService.client.auth.currentUser?.id;
    final bool isMe = widget.userId == null || widget.userId == myId;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
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
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
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
                          onPressed: _saveProfile,
                          child: const Text('Save Changes'),
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
              // Avatar Column
              Center(
                child: Column(
                  children: [
                    Container(
                      width: isMobile ? 140 : 180,
                      height: isMobile ? 140 : 180,
                      decoration: BoxDecoration(
                        color: OTheme.deepCharcoal,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                        image: _profile?.avatarUrl != null
                            ? DecorationImage(image: NetworkImage(_profile!.avatarUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _isUploading 
                          ? const Center(child: CircularProgressIndicator(color: OTheme.neonPink))
                          : (_profile?.avatarUrl == null
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(isMobile ? 30 : 40.0),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      color: OTheme.neonPink.withOpacity(0.3),
                                    ),
                                  ),
                                )
                              : null),
                    ),
                    if (isMe) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickImage,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(_isUploading ? 'Uploading...' : 'Upload Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: OTheme.neonPink,
                          side: const BorderSide(color: OTheme.neonPink),
                        ),
                      ),
                    ],
                    if (_profile?.isVerified == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
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
                          backgroundColor: OTheme.neonPink.withOpacity(0.1),
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
    
                    // Pronouns
                    _buildLabel('Pronouns'),
                    if (_isEditing)
                      DropdownButtonFormField<String>(
                        value: _selectedPronouns,
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
                            color: OTheme.neonPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: OTheme.neonPink.withOpacity(0.3)),
                          ),
                          child: Text(UserTag.format(i), style: const TextStyle(color: OTheme.neonPink, fontSize: 13)),
                        )).toList(),
                      )
                    else
                      const Text('No interests set', style: TextStyle(color: Colors.white24, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
