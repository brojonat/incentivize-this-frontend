import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'responsive_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About IncentivizeThis'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/bounties'); // Fallback to bounties if cannot pop
            }
          },
        ),
      ),
      body: CenteredConstrainedView(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to IncentivizeThis! 🥕',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Our Goal'),
              const SizedBox(height: 12),
              Text(
                "We're the bridge between innovative businesses and the creators who can get them the visibility they want.",
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'For Businesses: Create a Bounty'),
              const SizedBox(height: 12),
              _buildStep(
                theme,
                icon: Icons.add_circle_outline_rounded,
                title: '1. Create Your Bounty',
                description:
                    "Click the '+' button on the home screen, define your content requirements, and set a reward.",
              ),
              const SizedBox(height: 16),
              _buildStep(
                theme,
                icon: Icons.attach_money_rounded,
                title: '2. Fund It',
                description:
                    'Deposit funds to cover the rewards. Your bounty becomes active once funded.',
              ),
              const SizedBox(height: 16),
              _buildStep(
                theme,
                icon: Icons.rate_review_rounded,
                title: '3. Enjoy Your New Customers',
                description:
                    'Creators will fulfill your bounty, increasing your audience reach, and bringing you new customers.',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'For Creators: Fulfill a Bounty'),
              const SizedBox(height: 12),
              _buildStep(
                theme,
                icon: Icons.list_alt_rounded,
                title: '1. Discover Bounties',
                description:
                    'Browse available bounties. Each bounty has a reward for content that meets specific requirements.',
              ),
              const SizedBox(height: 16),
              _buildStep(
                theme,
                icon: Icons.link_rounded,
                title: '2. Submit Your Content',
                description:
                    'Found a bounty you can fulfill? Great! Create your content and submit a link to it through our platform.',
              ),
              const SizedBox(height: 16),
              _buildStep(
                theme,
                icon: Icons.account_balance_wallet_rounded,
                title: '3. Get Paid!',
                description:
                    'We\'ll review your submission and if it fulfills the bounty, we\'ll send the reward to your wallet. It\'s that simple!',
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Explore Bounties'),
                      onPressed: () => context.go('/bounties'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.forum_rounded),
                      label: const Text('Have questions? Join our Discord!'),
                      onPressed: () =>
                          _launchUrl('https://discord.gg/Sut96XYkKg'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // Consider showing an error message to the user
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildStep(ThemeData theme,
      {required IconData icon,
      required String title,
      required String description}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
