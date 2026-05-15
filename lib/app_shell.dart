import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAdminStatus();
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    await SupabaseService.updateOnlineStatus(isOnline);
  }

  Future<void> _checkAdminStatus() async {
    debugPrint('NAV: Checking Admin Status in AppShell');
    try {
      final profile = await SupabaseService.getMyProfile().timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isAdmin = profile?.isAdmin ?? false;
          _isLoading = false;
        });
        debugPrint('NAV: Admin status: $_isAdmin');
      }
    } catch (e) {
      debugPrint('NAV: Admin check FAILED: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await SupabaseService.updateOnlineStatus(false);
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Sign-out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? Drawer(
        backgroundColor: OTheme.black,
        child: SideNavBar(isDrawer: true, isAdmin: _isAdmin, onSignOut: _handleSignOut),
      ) : null,
      body: Row(
        children: [
          if (isDesktop) SideNavBar(isAdmin: _isAdmin, onSignOut: _handleSignOut),
          Expanded(
            child: Column(
              children: [
                TopNavBar(
                  isDesktop: isDesktop,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  onSignOut: _handleSignOut,
                ),
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: OTheme.neonPink))
                      : widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SideNavBar extends StatelessWidget {
  final bool isDrawer;
  final bool isAdmin;
  final VoidCallback onSignOut;
  const SideNavBar({super.key, this.isDrawer = false, this.isAdmin = false, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? null : 260,
      color: OTheme.black,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 48,
              ),
              if (isDrawer) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NavButton(
                    icon: Icons.home_outlined,
                    label: 'Hub',
                    path: '/hub',
                    isSelected: GoRouterState.of(context).uri.path == '/hub',
                    onTap: isDrawer ? () => Navigator.pop(context) : null,
                  ),
                  _NavButton(
                    icon: Icons.explore_outlined,
                    label: 'Discovery',
                    path: '/discovery',
                    isSelected: GoRouterState.of(context).uri.path == '/discovery',
                    onTap: isDrawer ? () => Navigator.pop(context) : null,
                  ),
                  _NavButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messaging',
                    path: '/messaging',
                    isSelected: GoRouterState.of(context).uri.path == '/messaging',
                    onTap: isDrawer ? () => Navigator.pop(context) : null,
                  ),
                  _NavButton(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Matchmaker',
                    path: '/matchmaker',
                    isSelected: GoRouterState.of(context).uri.path == '/matchmaker',
                    onTap: isDrawer ? () => Navigator.pop(context) : null,
                  ),
                  if (isAdmin)
                    _NavButton(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Console',
                      path: '/admin',
                      isSelected: GoRouterState.of(context).uri.path == '/admin',
                      onTap: isDrawer ? () => Navigator.pop(context) : null,
                    ),
                  const SizedBox(height: 32),
                  _NavButton(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    path: '/profile',
                    isSelected: GoRouterState.of(context).uri.path == '/profile',
                    onTap: isDrawer ? () => Navigator.pop(context) : null,
                  ),
                  _NavButton(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    path: '/settings',
                    isSelected: GoRouterState.of(context).uri.path == '/settings',
                    onTap: isDrawer ? () => Navigator.pop(context) : null,
                  ),
                  const SizedBox(height: 16),
                  _NavButton(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    path: '/login', // Path won't be used as we override onTap
                    isSelected: false,
                    onTap: onSignOut,
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

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          GoRouter.of(context).go(path);
          if (onTap != null) onTap!();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? OTheme.neonPink.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? OTheme.neonPink : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? OTheme.neonPink : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopNavBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onSignOut;
  final bool isDesktop;
  const TopNavBar({
    super.key, 
    required this.onMenuPressed, 
    required this.onSignOut,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: OTheme.black,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white70),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 12),
          ],
          if (!isDesktop)
            Image.asset(
              'assets/logo.png',
              height: 32,
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: OTheme.neonPink, size: 24),
            tooltip: 'Sign Out',
            onPressed: onSignOut,
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 18,
            backgroundColor: OTheme.deepCharcoal,
            child: Icon(Icons.person, size: 20, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
