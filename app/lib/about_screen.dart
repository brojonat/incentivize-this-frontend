import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              context.go('/'); // Fallback to home if cannot pop
            }
          },
        ),
      ),
      body: SingleChildScrollView(
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
            _buildSectionTitle(theme, 'How It Works'),
            const SizedBox(height: 12),
            _buildStep(
              theme,
              icon: Icons.list_alt_rounded,
              title: '1. Discover Bounties',
              description:
                  'Browse through a list of available bounties. Each bounty has specific requirements and a reward for content that meets them.',
            ),
            const SizedBox(height: 16),
            _buildStep(
              theme,
              icon: Icons.link_rounded,
              title: '2. Submit Your Content',
              description:
                  'Found a bounty you can fulfill? Great! Create your content (e.g., a Reddit post, a YouTube video, a tweet) according to the bounty requirements. Then, submit a link to your content through our platform.',
            ),
            const SizedBox(height: 16),
            _buildStep(
              theme,
              icon: Icons.account_balance_wallet_rounded,
              title: '3. Get Paid!',
              description:
                  'We\'ll review your submission and if it meets the bounty criteria, the reward will be sent to your wallet. Cash money baby, it\'s that simple!',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(theme, 'Our Goal'),
            const SizedBox(height: 12),
            Text(
              'We connect creators with opportunities to get paid for producing quality content that people want. Whether you\'re a writer, video creator, or social media enthusiast, IncentivizeThis provides a platform to monetize your content. Look, you\'re on the Internet anyway, you might as well get paid for it.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home_rounded),
                label: const Text('Explore Bounties'),
                onPressed: () => context.go('/bounties'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
