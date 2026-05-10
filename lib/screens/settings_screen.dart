import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                // In a real web app, we'd trigger a file download here.
                // For now, we'll show a success message with a data summary.
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
                  if (context.mounted) GoRouter.of(context).go('/auth');
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
