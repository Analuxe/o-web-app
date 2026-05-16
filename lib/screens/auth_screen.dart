import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;
  const AuthScreen({super.key, this.isSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isSignUp;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    isSignUp = widget.isSignUp;
  }

  Future<void> _handleAuth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (isSignUp) {
        await SupabaseService.signUp(_emailController.text, _passwordController.text);
      } else {
        await SupabaseService.signIn(_emailController.text, _passwordController.text);
      }
      if (mounted) GoRouter.of(context).go('/');
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('429')) {
        errorMessage = 'Too many attempts. Please wait a few minutes before trying again.';
      } else if (errorMessage.contains('Invalid login credentials')) {
        errorMessage = 'Check your email or password and try again.';
      }
      setState(() => _error = errorMessage);
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
      body: isMobile 
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left side: Brand Image/Gradient
        Expanded(
          flex: 1,
          child: _BrandSection(),
        ),
        // Right side: Form
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: _AuthForm(
              isSignUp: isSignUp,
              isLoading: _isLoading,
              error: _error,
              emailController: _emailController,
              passwordController: _passwordController,
              onAuth: _handleAuth,
              onToggleAuth: () => setState(() => isSignUp = !isSignUp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OTheme.neonPink,
                  OTheme.electricRedPink,
                  OTheme.black,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 16),
                const Text(
                  'Open up.',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: _AuthForm(
              isSignUp: isSignUp,
              isLoading: _isLoading,
              error: _error,
              emailController: _emailController,
              passwordController: _passwordController,
              onAuth: _handleAuth,
              onToggleAuth: () => setState(() => isSignUp = !isSignUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OTheme.neonPink,
            OTheme.electricRedPink,
            OTheme.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 160),
            const SizedBox(height: 24),
            const Text(
              'Open up.',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let loose.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  final bool isSignUp;
  final bool isLoading;
  final String? error;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onAuth;
  final VoidCallback onToggleAuth;

  const _AuthForm({
    required this.isSignUp,
    required this.isLoading,
    this.error,
    required this.emailController,
    required this.passwordController,
    required this.onAuth,
    required this.onToggleAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSignUp ? 'Create Account' : 'Welcome Back',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 12),
        Text(
          isSignUp 
            ? 'Come as you are. No judgment here.' 
            : 'Welcome back. We missed you.',
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
        if (error != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error!, 
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        _AuthField(
          label: isSignUp ? 'Email Address' : 'Email or Username', 
          hint: isSignUp ? 'name@example.com' : 'email or username', 
          controller: emailController
        ),
        const SizedBox(height: 24),
        _AuthField(
          label: 'Password', 
          hint: '••••••••', 
          isPassword: true, 
          controller: passwordController
        ),
        if (!isSignUp) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ),
        ],
        if (isSignUp) ...[
          const SizedBox(height: 24),
          const _AuthField(
            label: 'Confirm Password', 
            hint: '••••••••', 
            isPassword: true
          ),
        ],
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: isLoading ? null : onAuth,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
          ),
          child: isLoading 
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: OTheme.neonPink, strokeWidth: 2),
              )
            : Text(isSignUp ? 'Sign Up' : 'Sign In'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignUp ? 'Already have an account? ' : "Don't have an account? ",
              style: const TextStyle(color: Colors.white38),
            ),
            TextButton(
              onPressed: onToggleAuth,
              child: Text(
                isSignUp ? 'Sign In' : 'Sign Up',
                style: const TextStyle(color: OTheme.neonPink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;

  const _AuthField({
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
