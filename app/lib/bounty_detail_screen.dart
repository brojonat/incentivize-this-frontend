import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'bounty.dart';
import 'claim_dialog.dart';
import 'info_chip.dart';
import 'theme.dart';

class BountyDetailScreen extends StatelessWidget {
  final Bounty bounty;
  final String? walletAddress;
  final Function(String contentId, String walletAddress) onSubmitClaim;

  const BountyDetailScreen({
    Key? key,
    required this.bounty,
    this.walletAddress,
    required this.onSubmitClaim,
  }) : super(key: key);

  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ClaimDialog(
        bounty: bounty,
        initialWalletAddress: walletAddress,
        onSubmit: onSubmitClaim,
      ),
    );
  }

  String _formatRequirements(String description) {
    const String noRequirementsText = 'No specific requirements listed.';
    if (description == noRequirementsText) {
      return description;
    }

    // Split by newline, then split each line by ". " to get sentences.
    // Flatten the list, trim whitespace, filter empty strings, and add bullets.
    final List<String> requirements = description
        .split('\n')
        .expand((line) => line.split('. ')) // Split each line into sentences
        .map((sentence) => sentence.trim()) // Trim whitespace
        .where((sentence) => sentence.isNotEmpty) // Remove empty sentences
        // Add bullet point and ensure it ends with a period
        .map((sentence) =>
            '• ${sentence.endsWith('.') ? sentence : '$sentence.'}')
        .toList();

    return requirements.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Bounty Details'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with bounty title and status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InfoChip(
                        icon: Icons.monetization_on_outlined,
                        text:
                            '${bounty.bountyPerPost.toStringAsFixed(2)} per post',
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.device_hub_outlined,
                        text: bounty.platformType,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.article_outlined,
                        text: bounty.contentKind,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: bounty.remainingPostsDisplay,
                        color: theme.colorScheme.secondary,
                      ),
                      if (bounty.deadline != null &&
                          bounty.deadline!.year > 1970) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(bounty.deadline!),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: bounty.isActive
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              bounty.isActive
                                  ? Icons.verified_outlined
                                  : Icons.hourglass_empty,
                              size: 16,
                              color: bounty.isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bounty.isActive ? 'Active' : 'Closed',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: bounty.isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatRequirements(bounty.description),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: bounty.isActive
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _showClaimDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_task,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Claim This Bounty',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: null, // Disabled button
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bounty No Longer Available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
