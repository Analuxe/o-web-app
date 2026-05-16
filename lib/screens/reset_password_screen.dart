import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/services/supabase_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;

  Future<void> _handleUpdate() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter a new password.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SupabaseService.updatePassword(_passwordController.text);
      setState(() => _isSuccess = true);
      // Wait a bit then redirect
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/hub');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      backgroundColor: OTheme.black,
      body: Center(
        child: Container(
          maxWidth: 450,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 40),
          child: _isSuccess ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Enter your new password below.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        if (_error != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              _error!, 
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildField(
          label: 'New Password', 
          hint: '••••••••', 
          isPassword: true,
          controller: _passwordController
        ),
        const SizedBox(height: 24),
        _buildField(
          label: 'Confirm New Password', 
          hint: '••••••••', 
          isPassword: true,
          controller: _confirmPasswordController
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdate,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
          ),
          child: _isLoading 
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: OTheme.neonPink, strokeWidth: 2),
              )
            : const Text('Update Password'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
        const SizedBox(height: 32),
        const Text(
          'Password Updated',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your password has been successfully updated. Redirecting you to the hub...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: OTheme.neonPink),
      ],
    );
  }

  Widget _buildField({
    required String label, 
    required String hint, 
    bool isPassword = false,
    required TextEditingController controller
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: OTheme.deepCharcoal,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
