import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isUploading = false;
  Uint8List? _selectedImageBytes;
  String? _fileName;
  Map<String, dynamic>? _existingApplication;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    try {
      final app = await SupabaseService.getMyVerificationApplication();
      setState(() {
        _existingApplication = app;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _fileName = image.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedImageBytes == null || _fileName == null) return;

    setState(() => _isUploading = true);
    try {
      await SupabaseService.submitVerification(_selectedImageBytes!, _fileName!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification application submitted!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: OTheme.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: OTheme.neonPink)),
      );
    }

    return Scaffold(
      backgroundColor: OTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Identity Verification'),
      ),
      body: Center(
        child: Container(
          maxWidth: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 80, color: OTheme.neonPink),
              const SizedBox(height: 24),
              const Text(
                'Get Verified',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'To maintain a safe and premium community, we require users to verify their identity with a government-issued ID. Your ID will be stored securely and automatically deleted within 7 days of approval.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              if (_existingApplication != null) ...[
                _buildStatusCard(_existingApplication!['status']),
                const SizedBox(height: 24),
                if (_existingApplication!['status'] == 'rejected')
                  ElevatedButton(
                    onPressed: () => setState(() => _existingApplication = null),
                    child: const Text('Try Again'),
                  ),
              ] else ...[
                if (_selectedImageBytes != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OTheme.neonPink.withOpacity(0.5)),
                      image: DecorationImage(
                        image: MemoryImage(_selectedImageBytes!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: OTheme.deepCharcoal,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('Upload Government ID', style: TextStyle(color: Colors.white54)),
                          Text('(Passport, Driver License, etc.)', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_selectedImageBytes == null || _isUploading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isUploading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Submit for Review'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color color;
    IconData icon;
    String message;

    switch (status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.verified;
        message = 'Your identity has been verified!';
        break;
      case 'rejected':
        color = Colors.redAccent;
        icon = Icons.error_outline;
        message = 'Your application was rejected. Please try again with a clearer photo.';
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending_actions;
        message = 'Your application is currently under review. This usually takes less than 24 hours.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 16),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
