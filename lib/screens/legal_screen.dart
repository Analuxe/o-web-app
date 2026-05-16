import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:go_router/go_router.dart';

/// A reusable screen for rendering a legal document (ToS or Privacy Policy).
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc == LegalDoc.termsOfService
        ? _termsContent
        : _privacyContent;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: OTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(
          data.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 48,
            vertical: 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [OTheme.neonPink, OTheme.electricRedPink],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(data.icon, color: Colors.white, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last updated: ${data.lastUpdated}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Intro blurb
                Text(
                  data.intro,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 32),
                // Sections
                ...data.sections.map((s) => _LegalSection(section: s)),
                const SizedBox(height: 48),
                // Contact footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: OTheme.deepCharcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mail_outline, color: OTheme.neonPink, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Questions? Contact us at legal@joinoapp.com',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final _Section section;
  const _LegalSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section number + title
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: OTheme.neonPink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${section.number}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Body text
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              section.body,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
          // Optional bullets
          if (section.bullets != null) ...[
            const SizedBox(height: 8),
            ...section.bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, color: OTheme.neonPink, size: 5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
        ],
      ),
    );
  }
}

// ─── Data ────────────────────────────────────────────────────────────────────

enum LegalDoc { termsOfService, privacyPolicy }

class _LegalData {
  final String title;
  final String lastUpdated;
  final String intro;
  final IconData icon;
  final List<_Section> sections;
  const _LegalData({
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.icon,
    required this.sections,
  });
}

class _Section {
  final int number;
  final String title;
  final String body;
  final List<String>? bullets;
  const _Section({
    required this.number,
    required this.title,
    required this.body,
    this.bullets,
  });
}

// ─── Terms of Service Content ─────────────────────────────────────────────────

const _termsContent = _LegalData(
  title: 'Terms of Service',
  lastUpdated: 'May 16, 2025',
  icon: Icons.description_outlined,
  intro:
      'Welcome to O. By accessing or using the O platform, application, or any of its associated services '
      '("Services"), you agree to be bound by these Terms of Service ("Terms"). Please read them carefully. '
      'If you do not agree with any part of these Terms, you may not use our Services.',
  sections: [
    _Section(
      number: 1,
      title: 'Eligibility & Age Requirement',
      body:
          'O is an adult platform intended exclusively for users who are 18 years of age or older. '
          'By creating an account, you confirm that you meet this age requirement. We reserve the right to '
          'terminate any account we believe to belong to a minor, and to report suspected underage use to '
          'appropriate authorities. You must provide accurate and complete information during registration.',
    ),
    _Section(
      number: 2,
      title: 'User Accounts & Responsibility',
      body:
          'You are responsible for maintaining the confidentiality of your account credentials and for all '
          'activity that occurs under your account. You agree to notify us immediately of any unauthorized '
          'use of your account. O is not liable for losses caused by unauthorized access resulting from your '
          'failure to protect your credentials.',
      bullets: [
        'You may not transfer or sell your account to another person.',
        'You may not create multiple accounts for abusive purposes.',
        'Impersonating another person or creating a misleading profile is strictly prohibited.',
      ],
    ),
    _Section(
      number: 3,
      title: 'Community Standards & Prohibited Conduct',
      body:
          'O is built on a foundation of respect, consent, and radical authenticity. All users must adhere to '
          'our community standards at all times. The following conduct is strictly prohibited:',
      bullets: [
        'Harassment, threats, hate speech, or any conduct targeting users based on race, ethnicity, religion, gender, sexual orientation, disability, or any other protected characteristic.',
        'Sharing non-consensual intimate imagery (NCII) or any content depicting minors in a sexual context.',
        'Solicitation of illegal services, including sex work where prohibited by law.',
        'Scamming, phishing, or using the platform to defraud other users.',
        'Creating fake or misleading profiles, or misrepresenting your identity.',
        'Automated use of the platform (bots, scrapers) without express written permission.',
      ],
    ),
    _Section(
      number: 4,
      title: 'Content You Share',
      body:
          'By uploading photos, text, or other content to O, you grant us a non-exclusive, royalty-free, '
          'worldwide license to use, display, and distribute that content solely for the purpose of operating '
          'and improving the Services. You retain ownership of your content and may delete it at any time. '
          'You represent that you have the right to share any content you post, and that it does not infringe '
          'any third-party rights.',
    ),
    _Section(
      number: 5,
      title: 'Identity Validation',
      body:
          'O operates an identity validation system to promote authenticity and safety within the community. '
          'Validation is required to access certain features including messaging. Validation photos are '
          'reviewed solely for identity confirmation purposes and are stored securely. We do not use '
          'validation imagery for any marketing or promotional purposes.',
    ),
    _Section(
      number: 6,
      title: 'Subscription & Premium Features',
      body:
          'Certain features of O are available to Premium subscribers. Subscription fees are billed in advance '
          'on a recurring basis. Cancellations take effect at the end of the current billing period — no partial '
          'refunds are issued. O reserves the right to modify pricing with at least 30 days\' advance notice to '
          'affected subscribers.',
    ),
    _Section(
      number: 7,
      title: 'Termination',
      body:
          'We may suspend or permanently terminate your account at our sole discretion if we determine that '
          'you have violated these Terms, posed a risk to the safety of other users, or engaged in any conduct '
          'we deem harmful to the O community. You may delete your account at any time from Settings.',
    ),
    _Section(
      number: 8,
      title: 'Disclaimers & Limitation of Liability',
      body:
          'O is provided on an "as-is" and "as-available" basis without warranties of any kind. We do not '
          'guarantee that the Services will be uninterrupted or error-free. O is not responsible for the '
          'conduct of any user, online or offline. To the maximum extent permitted by law, O\'s total liability '
          'in connection with the Services shall not exceed the amount you paid to O in the 12 months preceding '
          'the claim.',
    ),
    _Section(
      number: 9,
      title: 'Governing Law & Dispute Resolution',
      body:
          'These Terms are governed by the laws of the State of New York, without regard to its conflict-of-law '
          'provisions. Any dispute arising from or relating to these Terms shall first be addressed through '
          'binding arbitration on an individual basis. You waive any right to participate in class-action '
          'litigation against O.',
    ),
    _Section(
      number: 10,
      title: 'Changes to These Terms',
      body:
          'We may revise these Terms at any time. When we do, we will update the "Last updated" date at the '
          'top of this page and notify you via email or in-app notification. Continued use of the Services '
          'after changes take effect constitutes your acceptance of the revised Terms.',
    ),
  ],
);

// ─── Privacy Policy Content ───────────────────────────────────────────────────

const _privacyContent = _LegalData(
  title: 'Privacy Policy',
  lastUpdated: 'May 16, 2025',
  icon: Icons.privacy_tip_outlined,
  intro:
      'Your privacy matters deeply to us. This Privacy Policy explains what information O collects, how we '
      'use it, who we share it with, and the rights you have over your data. O is committed to complying '
      'with applicable data protection laws, including GDPR and CCPA where relevant.',
  sections: [
    _Section(
      number: 1,
      title: 'Information We Collect',
      body: 'We collect information you provide directly and data generated through your use of the platform:',
      bullets: [
        'Account data: email address, username, display name, age, and password (stored as a cryptographic hash).',
        'Profile data: photos, bio, pronouns, sexual preference tags, relationship status, and interests.',
        'Location data: ZIP code and GPS coordinates (only if you grant location permission).',
        'Communication data: messages exchanged with other users on the platform.',
        'Validation data: identity photos submitted for the validation process.',
        'Usage data: device type, browser, pages visited, and features used, collected via server logs.',
      ],
    ),
    _Section(
      number: 2,
      title: 'How We Use Your Information',
      body: 'We use the information we collect to:',
      bullets: [
        'Provide and improve the O platform and its features.',
        'Match you with compatible users in your area based on your preferences.',
        'Verify your identity to maintain a safe, authentic community.',
        'Send you notifications about matches, messages, and platform updates.',
        'Investigate and enforce our Terms of Service and community standards.',
        'Comply with legal obligations and respond to lawful requests from authorities.',
      ],
    ),
    _Section(
      number: 3,
      title: 'Sexual Orientation & Sensitive Data',
      body:
          'Information about your sexual orientation, preferences, and related data you share on O constitutes '
          'sensitive personal information under many privacy laws. We process this data only with your explicit '
          'consent as provided when you create a profile. We do not sell or share this data with advertisers. '
          'This data is used exclusively to provide you with relevant matches and a personalized experience.',
    ),
    _Section(
      number: 4,
      title: 'Cookies & Tracking Technologies',
      body:
          'O uses a minimal set of cookies and similar technologies strictly necessary for the platform to '
          'function. We use Supabase session tokens to maintain your authenticated session. We do not use '
          'third-party advertising trackers or behavioral profiling cookies. You can control cookie settings '
          'through your browser, but disabling session cookies will prevent you from using the platform.',
    ),
    _Section(
      number: 5,
      title: 'How We Share Your Information',
      body:
          'O does not sell your personal data. We may share information in limited circumstances:',
      bullets: [
        'With other users: your public profile information (display name, photos, bio, tags) is visible to other O members.',
        'With service providers: we use Supabase for database and authentication services, bound by data processing agreements.',
        'For legal compliance: we may disclose data in response to valid legal processes such as court orders or subpoenas.',
        'In a merger or acquisition: your data may be transferred as part of any business transaction, with advance notice provided.',
      ],
    ),
    _Section(
      number: 6,
      title: 'Data Retention',
      body:
          'We retain your personal data for as long as your account is active or as needed to provide Services. '
          'When you delete your account, your profile and messages are deleted from our active databases within '
          '30 days. Some data may be retained in encrypted backups for up to 90 days before being purged. '
          'Validation photos are deleted within 7 days of account deletion.',
    ),
    _Section(
      number: 7,
      title: 'Your Rights',
      body: 'Depending on your location, you may have the following rights regarding your personal data:',
      bullets: [
        'Right of Access: Request a copy of the personal data we hold about you.',
        'Right to Rectification: Correct inaccurate data in your profile at any time.',
        'Right to Erasure ("Right to be Forgotten"): Delete your account and personal data.',
        'Right to Data Portability: Export a summary of your data from Settings → Export My Data.',
        'Right to Restrict Processing: Limit how we process your data in certain circumstances.',
        'Right to Object: Object to processing based on legitimate interests.',
        'Right to Withdraw Consent: Withdraw consent for sensitive data processing by deleting your account.',
      ],
    ),
    _Section(
      number: 8,
      title: 'Data Security',
      body:
          'O employs industry-standard security measures to protect your information, including TLS encryption '
          'for data in transit and row-level security (RLS) policies in our database to ensure users can only '
          'access their own data. Passwords are never stored in plain text. Validation images are stored in a '
          'private, access-controlled storage bucket. Despite our best efforts, no system is completely secure, '
          'and we cannot guarantee absolute security.',
    ),
    _Section(
      number: 9,
      title: 'Children\'s Privacy',
      body:
          'O is strictly for adults aged 18 and older. We do not knowingly collect personal information from '
          'anyone under 18. If we discover that a user is under 18, we will immediately terminate their account '
          'and delete all associated data. If you believe a minor has created an account, please contact us '
          'immediately at safety@joinoapp.com.',
    ),
    _Section(
      number: 10,
      title: 'Changes to This Policy',
      body:
          'We may update this Privacy Policy from time to time. When we do, we will revise the "Last updated" '
          'date and notify you via email or in-app notification for material changes. We encourage you to '
          'review this page periodically. Your continued use of the platform after any changes indicates '
          'your acceptance of the updated policy.',
    ),
  ],
);
