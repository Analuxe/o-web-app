import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String activeTab = 'analytics';
  int totalUsers = 0;
  int verifiedUsers = 0;
  int safetyFlags = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final client = SupabaseService.client;

    final usersRes = await client
        .from('profiles')
        .select('*', const FetchOptions(count: CountOption.exact));
    final verifiedRes = await client
        .from('profiles')
        .select('*', const FetchOptions(count: CountOption.exact))
        .eq('is_verified', true);
    final reportsRes = await client
        .from('reports')
        .select('*', const FetchOptions(count: CountOption.exact));

    if (mounted) {
      setState(() {
        totalUsers = usersRes.count ?? 0;
        verifiedUsers = verifiedRes.count ?? 0;
        safetyFlags = reportsRes.count ?? 0;
        isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Console',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Row(
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: activeTab == 'analytics' ? _buildAnalytics() : _buildInsights(),
            ),
          ),
        ],
      ),
    );
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
          child: Column(
            children: [
              _TrendRow(name: 'Techno', users: 128, growth: '+24%', isPositive: true),
              const Divider(color: Colors.white10, height: 32),
              _TrendRow(name: 'Kink', users: 94, growth: '+18%', isPositive: true),
              const Divider(color: Colors.white10, height: 32),
              _TrendRow(name: 'Digital Art', users: 156, growth: '+12%', isPositive: true),
              const Divider(color: Colors.white10, height: 32),
              _TrendRow(name: 'Travel', users: 210, growth: '-5%', isPositive: false),
            ],
          ),
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
        _HubRow(name: 'London Soho', count: 142, percentage: 0.8),
        _HubRow(name: 'Berlin Mitte', count: 89, percentage: 0.5),
        _HubRow(name: 'NYC Chelsea', count: 156, percentage: 0.9),
      ],
    );
  }

  Widget _buildFinancialHealth() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: OTheme.neonPink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OTheme.neonPink.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Financial Health',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Breakeven: 24 VIPs | Current: 28',
            style: TextStyle(color: OTheme.softRose, fontSize: 14),
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          const Text(
            'Est. Monthly Revenue',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
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
          color: isActive ? OTheme.neonPink.withOpacity(0.1) : Colors.transparent,
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
              color: isHighlight ? Colors.black.withOpacity(0.6) : Colors.white54,
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
                        color: OTheme.neonPink.withOpacity(0.3),
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
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
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
