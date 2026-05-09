import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedPronouns;
  final List<String> _selectedInterests = [];
  bool _isVerifying = false;

  final List<String> _availableInterests = [
    'Art', 'Music', 'Tech', 'Travel', 'Food', 'Fitness', 'Cinema', 'Gaming'
  ];

  void _nextStep() {
    if (_currentStep == 3 && !_isPhotoUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a document to continue')),
      );
      return;
    }
    
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isVerifying = true);
    
    // Simulate ID validation flow
    await Future.delayed(const Duration(seconds: 2));

    await SupabaseService.updateProfile({
      'display_name': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'bio': _bioController.text,
      'pronouns': _selectedPronouns,
      'interests': _selectedInterests,
      'is_verified': false, // Set to false for manual admin review
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
          maxWidth: 600,
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
              
              if (_isVerifying)
                const Column(
                  children: [
                    CircularProgressIndicator(color: OTheme.neonPink),
                    SizedBox(height: 24),
                    Text('Validating Identity Encryption...', style: TextStyle(color: Colors.white70)),
                  ],
                )
              else
                IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildIdentityStep(),
                    _buildDetailsStep(),
                    _buildInterestsStep(),
                    _buildVerificationStep(),
                  ],
                ),
              
              const SizedBox(height: 40),
              if (!_isVerifying)
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
        const Text('The Essentials', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('How should the community recognize you?', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
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
        const Text('Select at least 3 to find your match.', style: TextStyle(color: Colors.white54)),
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
              backgroundColor: Colors.white05,
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isPhotoUploaded = false;

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('O requires mandatory identity validation.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white05,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isPhotoUploaded ? OTheme.neonPink : Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _isPhotoUploaded ? Icons.check_circle_outline : Icons.shield_outlined, 
                    color: OTheme.neonPink, 
                    size: 40
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Secure Validation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Upload a government ID or selfie to verify your frequency.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => setState(() => _isPhotoUploaded = true),
                icon: const Icon(Icons.upload_file),
                label: Text(_isPhotoUploaded ? 'Photo Uploaded' : 'Select Document'),
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
      fillColor: Colors.white05,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(20),
    );
  }
}
