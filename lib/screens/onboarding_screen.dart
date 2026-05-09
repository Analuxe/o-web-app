import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedPronouns;
  final List<String> _selectedInterests = [];
  bool _isSaving = false;
  XFile? _pickedFile;

  final List<String> _availableInterests = [
    'Art', 'Music', 'Tech', 'Travel', 'Food', 'Fitness', 'Cinema', 'Gaming',
    'Techno', 'Design', 'Coffee', 'Outdoors', 'Books', 'Film',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedFile = image);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_usernameController.text.isEmpty || _nameController.text.isEmpty || _ageController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all essential fields')));
        return;
      }
    }
    
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    
    String? photoUrl;
    if (_pickedFile != null) {
      try {
        final bytes = await _pickedFile!.readAsBytes();
        final ext = _pickedFile!.name.split('.').last;
        photoUrl = await SupabaseService.uploadValidationPhoto(bytes, ext);
      } catch (e) {
        debugPrint('Upload failed: $e');
      }
    }

    await SupabaseService.updateProfile({
      'username': _usernameController.text,
      'display_name': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'bio': _bioController.text,
      'pronouns': _selectedPronouns,
      'interests': _selectedInterests,
      'avatar_url': photoUrl,
      'is_validated': false, // Human check pending
      'is_verified': false,  // ID check pending
    });

    if (mounted) {
      context.go('/discovery');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OTheme.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: OTheme.deepCharcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator
              Row(
                children: List.generate(4, (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? OTheme.neonPink : Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 40),
              
              if (_isSaving)
                const Column(
                  children: [
                    CircularProgressIndicator(color: OTheme.neonPink),
                    SizedBox(height: 24),
                    Text('Securing your frequency...', style: TextStyle(color: Colors.white70)),
                  ],
                )
              else
                IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildIdentityStep(),
                    _buildDetailsStep(),
                    _buildInterestsStep(),
                    _buildValidationStep(),
                  ],
                ),
              
              const SizedBox(height: 40),
              if (!_isSaving)
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: Text(_currentStep == 3 ? 'Complete Setup' : 'Continue'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Set your unique handle and display name.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        _buildField('Username', _usernameController, 'e.g. alex_vines'),
        const SizedBox(height: 20),
        _buildField('Display Name', _nameController, 'e.g. Alex'),
        const SizedBox(height: 20),
        _buildField('Age', _ageController, 'e.g. 28', isNumber: true),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Expression', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Tell us about your frequency.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        DropdownButtonFormField<String>(
          value: _selectedPronouns,
          dropdownColor: OTheme.deepCharcoal,
          decoration: _inputDecoration('Pronouns'),
          items: ['He/Him', 'She/Her', 'They/Them', 'Other'].map((p) => DropdownMenuItem(
            value: p,
            child: Text(p, style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedPronouns = val),
        ),
        const SizedBox(height: 20),
        _buildField('Bio', _bioController, 'A short note about you...', maxLines: 3),
      ],
    );
  }

  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Interests', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Select what moves you.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
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
              backgroundColor: Colors.white.withOpacity(0.05),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildValidationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Validation', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Confirm you are human to unlock messaging.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _pickedFile != null ? OTheme.neonPink : Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _pickedFile != null ? Icons.check_circle_outline : Icons.face_retouching_natural_outlined, 
                    color: OTheme.neonPink, 
                    size: 40
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Human Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Upload a selfie to validate your account. Messaging is disabled until approved.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Photo Selected ✅', style: TextStyle(color: OTheme.neonPink)),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(_pickedFile != null ? 'Change Photo' : 'Upload Selfie'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: OTheme.neonPink),
                  foregroundColor: OTheme.neonPink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
      style: const TextStyle(color: Colors.white),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(20),
    );
  }
}
