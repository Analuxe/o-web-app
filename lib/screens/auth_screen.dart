import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:go_router/go_router.dart';

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
      if (mounted) context.go('/discovery');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side: Brand Image/Gradient
          Expanded(
            flex: 1,
            child: Container(
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
                      'Link in. Branch out.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side: Form
          Expanded(
            flex: 1,
            child: Container(
              color: OTheme.black,
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: Column(
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
                      ? 'Join the community signal.' 
                      : 'Step back into the warm, moody space.',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 24),
                  ],
                  _AuthField(label: 'Email Address', hint: 'name@example.com', controller: _emailController),
                  const SizedBox(height: 24),
                  _AuthField(label: 'Password', hint: '••••••••', isPassword: true, controller: _passwordController),
                  if (isSignUp) ...[
                    const SizedBox(height: 24),
                    const _AuthField(label: 'Confirm Password', hint: '••••••••', isPassword: true),
                  ],
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
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
                        onPressed: () => setState(() => isSignUp = !isSignUp),
                        child: Text(
                          isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(color: OTheme.neonPink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
