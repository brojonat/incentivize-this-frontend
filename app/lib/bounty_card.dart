import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting

import 'bounty.dart';
import 'info_chip.dart';

class BountyCard extends StatelessWidget {
  final Bounty bounty;
  final VoidCallback onTap;

  const BountyCard({
    super.key,
    required this.bounty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy'); // Date formatter

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start, // Align top
                children: [
                  Expanded(
                    child: Text(
                      bounty.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2, // Allow two lines for title
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8), // Add spacing
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bounty
                              .isClaimable // Color is now based on Listening, Paying, or AwaitingFunding
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.outline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bounty.rawStatus == 'AwaitingFunding' ||
                                  bounty.rawStatus == 'TransferringFee'
                              ? Icons.hourglass_top_outlined
                              : (bounty.rawStatus == 'Listening'
                                  ? Icons.play_circle_outline
                                  : (bounty.rawStatus == 'Paying'
                                      ? Icons.payment_outlined
                                      : (bounty.rawStatus == 'Refunded' ||
                                              bounty.rawStatus == 'Cancelled'
                                          ? Icons
                                              .stop_circle_outlined // Changed to stop icon
                                          : Icons.pause_circle_outline))),
                          size: 16,
                          color: bounty.isClaimable
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bounty.displayStatus, // Use new displayStatus getter
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: bounty.isClaimable
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
              const SizedBox(height: 12), // Increased spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end, // Align bottom
                children: [
                  // Use Expanded and Wrap for InfoChips
                  Expanded(
                    child: Wrap(
                      spacing: 8.0, // Horizontal space between chips
                      runSpacing: 4.0, // Vertical space between lines
                      children: [
                        InfoChip(
                          icon: Icons.monetization_on_outlined,
                          text:
                              '${bounty.bountyPerPost.toStringAsFixed(2)} per post',
                          color: Colors.green.shade700,
                        ),
                        InfoChip(
                          icon: Icons.device_hub_outlined,
                          text: bounty.platformKind,
                          color: theme.colorScheme.tertiary,
                        ),
                        InfoChip(
                          icon: Icons.article_outlined,
                          text: bounty.contentKind,
                          color: Colors.orange.shade700,
                        ),
                        InfoChip(
                          icon: Icons.inventory_2_outlined,
                          text: bounty.remainingPostsDisplay,
                          color: theme.colorScheme.secondary,
                        ),
                        if (bounty.deadline != null &&
                            bounty.deadline!.year > 1970)
                          InfoChip(
                            icon: Icons.schedule,
                            text: dateFormat.format(bounty.deadline!),
                            color: theme.colorScheme.tertiary,
                          ),
                      ],
                    ),
                  ),
                  // Keep View Details button on the right
                  Container(
                    // Removed animation for simplicity in card view
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withOpacity(0.1), // Subtle background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color:
                          theme.colorScheme.primary, // Icon color matches theme
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
