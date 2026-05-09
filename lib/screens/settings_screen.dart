import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 48),
            
            _buildSection(context, 'Account', [
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Account Security',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 32),
            _buildSection(context, 'Legal', [
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
            
            const Spacer(),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (context.mounted) context.go('/auth');
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

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: OTheme.softRose, fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildSettingTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }
}
