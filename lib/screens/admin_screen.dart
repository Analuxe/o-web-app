import 'package:o_web/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:o_web/services/dummy_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String activeTab = 'analytics';
  List<Profile> reputationAlerts = [];
  bool isLoadingReputation = false;
  int totalUsers = 0;
  int verifiedUsers = 0;
  int safetyFlags = 0;
  bool isLoadingStats = true;
  List<Profile> unvalidatedUsers = [];
  bool isLoadingModeration = false;
  List<Map<String, dynamic>> pendingVerifications = [];
  bool isLoadingVerifications = false;
  bool _isAdmin = false;
  bool _isCheckingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final profile = await SupabaseService.getMyProfile();
    if (mounted) {
      setState(() {
        _isAdmin = profile?.isAdmin ?? false;
        _isCheckingAccess = false;
      });
      
      if (_isAdmin) {
        _loadStats();
        _loadUnvalidatedUsers();
        _loadVerifications();
      }
    }
  }

  Future<void> _loadStats() async {
    final client = SupabaseService.client;

    final usersRes = await client
        .from('profiles')
        .select()
        .count(CountOption.exact);
    final verifiedRes = await client
        .from('profiles')
        .select()
        .eq('is_verified', true)
        .count(CountOption.exact);
    final reportsRes = await client
        .from('reports')
        .select()
        .count(CountOption.exact);

    if (mounted) {
      setState(() {
        totalUsers = usersRes.count;
        verifiedUsers = verifiedRes.count;
        safetyFlags = reportsRes.count;
        isLoadingStats = false;
      });
    }
  }

  Future<void> _loadUnvalidatedUsers() async {
    setState(() => isLoadingModeration = true);
    final client = SupabaseService.client;
    final res = await client
        .from('profiles')
        .select()
        .eq('is_validated', false);
    
    if (mounted) {
      setState(() {
        unvalidatedUsers = (res as List).map<Profile>((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
        isLoadingModeration = false;
      });
    }
  }

  Future<void> _validateUser(String userId) async {
    await SupabaseService.client
        .from('profiles')
        .update({'is_validated': true})
        .eq('id', userId);
    _loadUnvalidatedUsers();
    _loadStats();
    _loadReputationAlerts();
  }

  Future<void> _loadVerifications() async {
    setState(() => isLoadingVerifications = true);
    try {
      final data = await SupabaseService.getPendingVerifications();
      setState(() => pendingVerifications = data);
    } catch (e) {
      safeLog('Error loading verifications: $e');
    } finally {
      setState(() => isLoadingVerifications = false);
    }
  }

  Future<void> _processVerification(String id, String status) async {
    await SupabaseService.updateVerificationStatus(id, status);
    _loadVerifications();
    _loadStats();
  }

  Future<void> _viewId(String path) async {
    try {
      final url = await SupabaseService.getVerificationIdUrl(path);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: OTheme.deepCharcoal,
            title: const Text('Government ID', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 800,
              height: 600,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading ID: $e')));
      }
    }
  }

  Future<void> _loadReputationAlerts() async {
    setState(() => isLoadingReputation = true);
    try {
      final data = await SupabaseService.getReputationAlerts();
      setState(() {
        reputationAlerts = (data as List).map<Profile>((d) => Profile.fromJson(d as Map<String, dynamic>)).toList();
        // Sort by thumbs down count descending
        reputationAlerts.sort((a, b) => b.thumbsDownCount.compareTo(a.thumbsDownCount));
      });
    } catch (e) {
      safeLog('Error loading reputation: $e');
    } finally {
      setState(() => isLoadingReputation = false);
    }
  }

  void _showAddAdminDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: OTheme.deepCharcoal,
        title: const Text('Promote to Admin', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the username of the user you want to promote.', 
              style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'username',
                prefixText: '@',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              style: const TextStyle(color: Colors.white),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = controller.text.trim();
              if (username.isEmpty) return;
              
              try {
                await SupabaseService.promoteToAdmin(username);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('User @$username is now an Admin'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  void _navigateBasedOnAuth() {
    final isAuthenticated = SupabaseService.client.auth.currentUser != null;
    GoRouter.of(context).go(isAuthenticated ? '/hub' : '/auth');
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccess) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    if (!_isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Access Denied',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You do not have the clearance to access the Admin Console.',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _navigateBasedOnAuth,
              child: const Text('Return to Safety'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Admin Console',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TabButton(
                    label: 'Analytics',
                    isActive: activeTab == 'analytics',
                    onTap: () => setState(() => activeTab = 'analytics'),
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Insights',
                    isActive: activeTab == 'insights',
                    onTap: () => setState(() => activeTab = 'insights'),
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Moderation',
                    isActive: activeTab == 'moderation',
                    onTap: () => setState(() => activeTab = 'moderation'),
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Reputation',
                    isActive: activeTab == 'reputation',
                    onTap: () => setState(() => activeTab = 'reputation'),
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Verifications',
                    isActive: activeTab == 'verifications',
                    onTap: () => setState(() => activeTab = 'verifications'),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await DummyDataService.seedDummyData();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dummy Data Seeded Successfully'), backgroundColor: Colors.green),
                        );
                        _loadStats();
                        _loadUnvalidatedUsers();
                        _loadVerifications();
                        _loadReputationAlerts();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error seeding data: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    icon: const Icon(Icons.storage, size: 16),
                    label: const Text('Seed UAT Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OTheme.neonPink.withValues(alpha: 0.1),
                      foregroundColor: OTheme.neonPink,
                      side: const BorderSide(color: OTheme.neonPink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await DummyDataService.clearDummyData();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dummy Data Cleared Successfully'), backgroundColor: Colors.orange),
                        );
                        _loadStats();
                        _loadUnvalidatedUsers();
                        _loadVerifications();
                        _loadReputationAlerts();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error clearing data: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Clear UAT Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddAdminDialog,
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('Add Moderator'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OTheme.neonPink.withValues(alpha: 0.1),
                      foregroundColor: OTheme.neonPink,
                      side: const BorderSide(color: OTheme.neonPink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (activeTab) {
      case 'analytics': return _buildAnalytics();
      case 'insights': return _buildInsights();
      case 'moderation': return _buildModeration();
      case 'reputation': return _buildReputation();
      case 'verifications': return _buildVerifications();
      default: return _buildAnalytics();
    }
  }

  Widget _buildAnalytics() {
    if (isLoadingStats) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: 'Total Users',
              value: totalUsers.toString(),
              icon: Icons.people_outline,
            ),
            const StatCard(
              title: 'VIP Subscribers',
              value: '28',
              icon: Icons.star_outline,
              isHighlight: true,
            ),
            StatCard(
              title: 'Verified Profiles',
              value: verifiedUsers.toString(),
              icon: Icons.verified_user_outlined,
            ),
            StatCard(
              title: 'Safety Flags',
              value: safetyFlags.toString(),
              icon: Icons.flag_outlined,
              isDanger: true,
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildHubDensity(),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 1,
              child: _buildFinancialHealth(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interest Trends',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: OTheme.deepCharcoal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              _TrendRow(name: 'Techno', users: 128, growth: '+24%', isPositive: true),
              Divider(color: Colors.white10, height: 32),
              _TrendRow(name: 'Kink', users: 94, growth: '+18%', isPositive: true),
              Divider(color: Colors.white10, height: 32),
              _TrendRow(name: 'Digital Art', users: 156, growth: '+12%', isPositive: true),
              Divider(color: Colors.white10, height: 32),
              _TrendRow(name: 'Travel', users: 210, growth: '-5%', isPositive: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeration() {
    if (isLoadingModeration) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }
    
    if (unvalidatedUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Text('No users pending validation.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Validation',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: unvalidatedUsers.length,
          itemBuilder: (context, index) {
            final user = unvalidatedUsers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OTheme.deepCharcoal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    backgroundColor: Colors.white10,
                    child: user.avatarUrl == null ? const Icon(Icons.person, color: OTheme.neonPink) : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('@${user.username ?? 'anon'}', style: const TextStyle(color: OTheme.neonPink, fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _validateUser(user.id),
                    style: ElevatedButton.styleFrom(backgroundColor: OTheme.neonPink),
                    child: const Text('Validate', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReputation() {
    if (isLoadingReputation) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    final highRiskUsers = reputationAlerts.where((u) => u.thumbsDownCount > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reputation Monitor',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Users with "Thumbs Down" reports from verified accounts.',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 32),
        if (highRiskUsers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Text('No reputation alerts at this time.', style: TextStyle(color: Colors.white24)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highRiskUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final user = highRiskUsers[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OTheme.deepCharcoal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: user.thumbsDownCount >= 3 ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      backgroundColor: Colors.white10,
                      child: user.avatarUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text('@${user.username}', style: const TextStyle(color: OTheme.neonPink, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: user.thumbsDownCount >= 3 ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: user.thumbsDownCount >= 3 ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.thumb_down_alt,
                            size: 14,
                            color: user.thumbsDownCount >= 3 ? Colors.redAccent : Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${user.thumbsDownCount} Thumbs Down',
                            style: TextStyle(
                              color: user.thumbsDownCount >= 3 ? Colors.redAccent : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.block, color: Colors.redAccent, size: 20),
                      onPressed: () async {
                        await SupabaseService.blockUser(user.id);
                        _loadReputationAlerts();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVerifications() {
    if (isLoadingVerifications) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    if (pendingVerifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Text('No pending ID verifications.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID Verification Requests',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingVerifications.length,
          itemBuilder: (context, index) {
            final app = pendingVerifications[index];
            final profile = app['profiles'] as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OTheme.deepCharcoal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url'] as String) : null,
                    backgroundColor: Colors.white10,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile['display_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('@${profile['username'] ?? 'anon'}', style: const TextStyle(color: OTheme.neonPink, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _viewId(app['id_image_url']),
                    icon: const Icon(Icons.badge, size: 16),
                    label: const Text('View ID'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _processVerification(app['id'], 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _processVerification(app['id'], 'rejected'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: const Text('Reject', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHubDensity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geo-Hub Density',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        const _HubRow(name: 'London Soho', count: 142, percentage: 0.8),
        const _HubRow(name: 'Berlin Mitte', count: 89, percentage: 0.5),
        const _HubRow(name: 'NYC Chelsea', count: 156, percentage: 0.9),
      ],
    );
  }

  Widget _buildFinancialHealth() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: OTheme.neonPink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OTheme.neonPink.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Text(
            'Financial Health',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Breakeven: 24 VIPs | Current: 28',
            style: TextStyle(color: OTheme.softRose, fontSize: 14),
          ),
          SizedBox(height: 32),
          Divider(color: Colors.white10),
          SizedBox(height: 24),
          Text(
            'Est. Monthly Revenue',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            '\$279.72',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: OTheme.neonPink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? OTheme.neonPink.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? OTheme.neonPink : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? OTheme.neonPink : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isHighlight;
  final bool isDanger;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isHighlight = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighlight ? OTheme.neonPink : OTheme.deepCharcoal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isHighlight ? Colors.black : (isDanger ? Colors.red : OTheme.neonPink),
            size: 24,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.black : Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isHighlight ? Colors.black.withValues(alpha: 0.6) : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  final String name;
  final int count;
  final double percentage;

  const _HubRow({
    required this.name,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$count users', style: const TextStyle(color: OTheme.softRose, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: OTheme.neonPink,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: OTheme.neonPink.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  final String name;
  final int users;
  final String growth;
  final bool isPositive;

  const _TrendRow({
    required this.name,
    required this.users,
    required this.growth,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$users active users', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            growth,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
