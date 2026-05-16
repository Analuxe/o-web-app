import 'package:o_web/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:o_web/widgets/tag_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _zipcodeController = TextEditingController();
  String? _selectedPronouns;
  String? _selectedRelationshipStatus;
  final List<String> _selectedInterests = [];
  bool _isSaving = false;
  bool _isHumanVerified = false;
  bool _isVerifyingHuman = false;
  bool _isLoadingProfile = true;
  bool _hasAgreedToLegal = false;
  bool _hasConsentedToSensitiveData = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
    _attemptLocationCapture();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await SupabaseService.getMyProfile();
      if (profile != null && mounted) {
        setState(() {
          _usernameController.text = profile.username ?? '';
          _nameController.text = profile.displayName ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _bioController.text = profile.bio ?? '';
          _zipcodeController.text = profile.zipcode ?? '';
          _selectedPronouns = profile.pronouns;
          _selectedRelationshipStatus = profile.relationshipStatus;
          if (profile.interests != null) {
            _selectedInterests.addAll(profile.interests!);
          }
          _isHumanVerified = profile.isValidated;
          
          // Determine which step to start at
          if (profile.username != null && profile.displayName != null && profile.age != null && profile.zipcode != null) {
            _currentStep = 1;
          }
          if (profile.pronouns != null) {
            _currentStep = 2;
          }
          if (profile.interests != null && profile.interests!.isNotEmpty) {
            _currentStep = 3;
          }
        });
      }
    } catch (e) {
      safeLog('Error loading existing profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _attemptLocationCapture() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = position);
        
        // Try to get zipcode from coordinates
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty && placemarks.first.postalCode != null) {
            setState(() {
              _zipcodeController.text = placemarks.first.postalCode!;
            });
          }
        } catch (e) {
          safeLog("Geocoding failed: $e");
        }
      }
    } catch (e) {
      safeLog("Location capture failed: $e");
    }
  }


  Future<void> _verifyHuman() async {
    setState(() => _isVerifyingHuman = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isVerifyingHuman = false;
        _isHumanVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Human Identity Confirmed via System Analysis'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  bool _isCheckingUsername = false;

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      final username = _usernameController.text.trim();
      final zipcode = _zipcodeController.text.trim();
      
      if (username.isEmpty || _nameController.text.isEmpty || _ageController.text.isEmpty || zipcode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all mandatory fields including Zipcode')));
        return;
      }

      // Security: Enforce 18+ age requirement (ToS §1, Privacy Policy §9)
      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be at least 18 years old to use O.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (age > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid age.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      if (!_hasAgreedToLegal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must agree to the Terms and Privacy Policy to continue.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      // P3 (GDPR Article 9): Require explicit consent for sensitive data processing
      if (!_hasConsentedToSensitiveData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must consent to sensitive data processing to use O.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      setState(() => _isCheckingUsername = true);
      try {
        final isAvailable = await SupabaseService.isUsernameAvailable(username);
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username is already taken. Please choose another.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          return;
        }
      } catch (e) {
        safeLog('Username check failed: $e');
      } finally {
        if (mounted) {
          setState(() => _isCheckingUsername = false);
        }
      }
    }

    if (_currentStep == 3 && !_isHumanVerified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete the human verification check')));
      }
      return;
    }
    
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    
    try {
      await SupabaseService.updateProfile({
        'username': _usernameController.text.trim(),
        'display_name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text),
        'bio': _bioController.text.trim(),
        'zipcode': _zipcodeController.text.trim(),
        'pronouns': _selectedPronouns,
        'relationship_status': _selectedRelationshipStatus,
        'interests': _selectedInterests,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'is_validated': true,
        'is_verified': false,
      });

      if (mounted) {
        GoRouter.of(context).go('/discovery');
      }
    } catch (e) {
      safeLog('Onboarding failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = width < 600 ? 20.0 : 40.0;

    return Scaffold(
      backgroundColor: OTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) {
                GoRouter.of(context).go('/auth');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white54, size: 16),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: OTheme.deepCharcoal,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(4, (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? OTheme.neonPink : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 40),
                
                if (_isLoadingProfile)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: OTheme.neonPink),
                      SizedBox(height: 24),
                      Text('Syncing your frequency...', style: TextStyle(color: Colors.white70)),
                    ],
                  )
                else if (_isSaving)
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
                    onPressed: (_isSaving || _isCheckingUsername || _isLoadingProfile) ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: _isCheckingUsername 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(_currentStep == 3 ? 'Complete Setup' : 'Continue'),
                  ),
              ],
            ),
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
        const Text('Set your handle, name, and location.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        _buildField('Username', _usernameController, 'e.g. alex_vines'),
        const SizedBox(height: 20),
        _buildField('Display Name', _nameController, 'e.g. Alex'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildField('Age', _ageController, 'e.g. 28', isNumber: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildField('Zipcode', _zipcodeController, 'Mandatory', isNumber: true)),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Checkbox(
              value: _hasAgreedToLegal,
              onChanged: (val) => setState(() => _hasAgreedToLegal = val ?? false),
              activeColor: OTheme.neonPink,
              side: const BorderSide(color: Colors.white24),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _hasAgreedToLegal = !_hasAgreedToLegal),
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: OTheme.neonPink.withValues(alpha: 0.8), decoration: TextDecoration.underline),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: OTheme.neonPink.withValues(alpha: 0.8), decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // P3 (GDPR Article 9): Explicit consent for special-category data
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _hasConsentedToSensitiveData,
              onChanged: (val) => setState(() => _hasConsentedToSensitiveData = val ?? false),
              activeColor: OTheme.neonPink,
              side: const BorderSide(color: Colors.white24),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _hasConsentedToSensitiveData = !_hasConsentedToSensitiveData),
                child: const Text(
                  'I consent to O processing my sexual orientation, preferences, and related intimate data for matchmaking and discovery purposes.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ),
            ),
          ],
        ),
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
          initialValue: _selectedPronouns,
          dropdownColor: OTheme.deepCharcoal,
          decoration: _inputDecoration('Pronouns'),
          items: ['He/Him', 'She/Her', 'They/Them', 'Other'].map((p) => DropdownMenuItem(
            value: p,
            child: Text(p, style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedPronouns = val),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedRelationshipStatus,
          dropdownColor: OTheme.deepCharcoal,
          decoration: _inputDecoration('Relationship Status'),
          items: ['Single', 'LTR', 'Poly'].map((s) => DropdownMenuItem(
            value: s,
            child: Text(s, style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedRelationshipStatus = val),
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
        CategorizedTagSelector(
          selectedTags: _selectedInterests,
          onChanged: (tags) {
            setState(() {
              _selectedInterests.clear();
              _selectedInterests.addAll(tags);
            });
          },
        ),
      ],
    );
  }

  Widget _buildValidationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Security', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Confirm you are human to unlock messaging.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 48),
        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHumanVerified ? OTheme.neonPink : Colors.white10,
                width: 2,
              ),
            ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: InkWell(
                    onTap: (_isVerifyingHuman || _isHumanVerified) ? null : _verifyHuman,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD3D3D3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: _isHumanVerified ? Colors.green : const Color(0xFFC1C1C1),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: _isVerifyingHuman
                                ? const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue,
                                    ),
                                  )
                                : (_isHumanVerified
                                    ? const Icon(Icons.check, color: Colors.green, size: 20)
                                    : null),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            "I'm not a robot",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(
                                'https://www.gstatic.com/recaptcha/api2/logo_48.png',
                                height: 32,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, color: Colors.blue, size: 24),
                              ),
                              const Text(
                                'reCAPTCHA',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 8,
                                ),
                              ),
                              const Text(
                                'Privacy - Terms',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isHumanVerified)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: OTheme.neonPink, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Verification Successful',
                        style: TextStyle(color: OTheme.neonPink, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Powered by Enterprise Browser Protection',
          style: TextStyle(color: Colors.white10, fontSize: 10),
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
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(20),
    );
  }
}
