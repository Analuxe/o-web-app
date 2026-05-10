import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _zipcodeController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    final profile = await SupabaseService.getMyProfile();
    if (mounted) {
      setState(() {
        _zipcodeController.text = profile?.zipcode ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshLocation() async {
    setState(() => _isSaving = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        _currentPosition = position;
        
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty && placemarks.first.postalCode != null) {
          setState(() {
            _zipcodeController.text = placemarks.first.postalCode!;
          });
        }
        
        await SupabaseService.updateProfile({
          'zipcode': _zipcodeController.text,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh location: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveZipcode() async {
    if (_zipcodeController.text.trim().isEmpty) return;
    
    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateProfile({
        'zipcode': _zipcodeController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zipcode saved!'), backgroundColor: OTheme.neonPink),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OTheme.deepCharcoal,
        title: const Text('Export Data', style: TextStyle(color: Colors.white)),
        content: const Text(
          'A summary of your profile, connections, and activity counts will be prepared for download. Proceed?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final data = await SupabaseService.exportUserData();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: OTheme.deepCharcoal,
                      title: const Text('Data Ready', style: TextStyle(color: Colors.white)),
                      content: SingleChildScrollView(
                        child: Text(data.toString(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OTheme.deepCharcoal,
        title: const Text('Delete Account?', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'This action is permanent. All your profile data, messages, and connections will be erased. You cannot undo this.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.deleteAccount();
              if (context.mounted) GoRouter.of(context).go('/auth');
            },
            child: const Text('Delete Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 48),
            
            _buildSection('Discovery & Location', [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _zipcodeController,
                            decoration: InputDecoration(
                              labelText: 'Profile Zipcode',
                              labelStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) => _saveZipcode(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveZipcode,
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _refreshLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(_isSaving ? 'Refreshing...' : 'Refresh GPS Location'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: OTheme.neonPink,
                        side: const BorderSide(color: OTheme.neonPink),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSection('Account Security', [
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.download_outlined,
                title: 'Export My Data',
                onTap: () => _showExportDialog(context),
              ),
              _buildSettingTile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                onTap: () => _showDeleteConfirmation(context),
                titleColor: Colors.redAccent.withOpacity(0.8),
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSection('Legal', [
              _buildSettingTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 64),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (mounted) GoRouter.of(context).go('/auth');
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: OTheme.softRose, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: OTheme.deepCharcoal,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color titleColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }
}
