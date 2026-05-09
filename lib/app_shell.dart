import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) const SideNavBar(),
          Expanded(
            child: Column(
              children: [
                if (!isDesktop) const TopNavBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SideNavBar extends StatelessWidget {
  const SideNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: OTheme.black,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 64,
          ),
          const SizedBox(height: 48),
          _NavButton(
            icon: Icons.explore_outlined,
            label: 'Discovery',
            path: '/discovery',
            isSelected: GoRouterState.of(context).uri.toString() == '/discovery',
          ),
          _NavButton(
            icon: Icons.chat_bubble_outline,
            label: 'Messaging',
            path: '/messaging',
            isSelected: GoRouterState.of(context).uri.toString() == '/messaging',
          ),
          _NavButton(
            icon: Icons.auto_awesome_outlined,
            label: 'Matchmaker',
            path: '/matchmaker',
            isSelected: GoRouterState.of(context).uri.toString() == '/matchmaker',
          ),
          _NavButton(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Admin Console',
            path: '/admin',
            isSelected: GoRouterState.of(context).uri.toString() == '/admin',
          ),
          const Spacer(),
          _NavButton(
            icon: Icons.person_outline,
            label: 'Profile',
            path: '/profile',
            isSelected: GoRouterState.of(context).uri.toString() == '/profile',
          ),
          _NavButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            path: '/settings',
            isSelected: false,
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

  const _NavButton({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.go(path),
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
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: OTheme.black,
      child: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 40,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.menu, color: OTheme.neonPink),
            onPressed: () {
              // Open mobile drawer
            },
          ),
        ],
      ),
    );
  }
}
