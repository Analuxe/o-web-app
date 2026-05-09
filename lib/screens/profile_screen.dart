import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedPronouns;
  List<String> _selectedInterests = [];

  final List<String> _availableInterests = [
    'Art', 'Music', 'Tech', 'Travel', 'Food', 'Fitness', 'Cinema', 'Gaming',
    'Techno', 'Design', 'Coffee', 'Outdoors', 'Books', 'Film',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getMyProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
      if (profile != null) {
        _displayNameController.text = profile.displayName ?? '';
        _bioController.text = profile.bio ?? '';
        _selectedPronouns = profile.pronouns;
        _selectedInterests = List.from(profile.interests ?? []);
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    await SupabaseService.updateProfile({
      'display_name': _displayNameController.text.isEmpty ? null : _displayNameController.text,
      'bio': _bioController.text.isEmpty ? null : _bioController.text,
      'pronouns': _selectedPronouns,
      'interests': _selectedInterests,
    });
    await _loadProfile();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Profile', style: Theme.of(context).textTheme.displayLarge),
              if (!_isEditing)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                )
              else
                Row(
                  children: [
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
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Column
              Column(
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: OTheme.deepCharcoal,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      image: _profile?.avatarUrl != null
                          ? DecorationImage(image: NetworkImage(_profile!.avatarUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _profile?.avatarUrl == null
                        ? const Icon(Icons.person, size: 80, color: OTheme.neonPink)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Upload Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OTheme.neonPink,
                      side: const BorderSide(color: OTheme.neonPink),
                    ),
                  ),
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
                  ],
                ],
              ),
              const SizedBox(width: 48),
              // Info Column
              Expanded(
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) _selectedInterests.add(interest);
                                else _selectedInterests.remove(interest);
                              });
                            },
                            selectedColor: OTheme.neonPink.withOpacity(0.2),
                            checkmarkColor: OTheme.neonPink,
                            labelStyle: TextStyle(color: isSelected ? OTheme.neonPink : Colors.white70),
                            backgroundColor: Colors.white05,
                          );
                        }).toList(),
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
                          child: Text(i, style: const TextStyle(color: OTheme.neonPink, fontSize: 13)),
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

  void _buildLabel(String label) {}

  Widget _buildLabelWidget(String label) {
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelWidget(label),
        if (isEditing)
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: value == 'Not set' ? Colors.white24 : Colors.white,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white05,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
