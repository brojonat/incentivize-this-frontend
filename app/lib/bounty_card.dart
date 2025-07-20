import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'bounty.dart';
import 'funding_qr_dialog.dart';
import 'info_chip.dart';
import 'notification_service.dart';

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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isVerySmallScreen = MediaQuery.of(context).size.width < 450;
    final titleStyle = isSmallScreen
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          )
        : theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          );

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
                      style: titleStyle,
                      maxLines: 2, // Allow two lines for title
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8), // Add spacing
                  Builder(builder: (context) {
                    final statusInfo = bounty.getStatusInfo(theme);
                    return InfoChip(
                      icon: statusInfo.icon,
                      text: statusInfo.text,
                      color: statusInfo.textColor,
                      backgroundColor: statusInfo.backgroundColor,
                      textColor: statusInfo.textColor,
                    );
                  }),
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
                          text: bounty.bountyPerPost.isFinite &&
                                  bounty.bountyPerPost > 0
                              ? '\$${bounty.bountyPerPost.toStringAsFixed(2)}'
                              : 'Unfunded',
                          color: bounty.bountyPerPost > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
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
                        if (bounty.tier != 8)
                          InfoChip(
                            icon: bounty.tierInfo(theme).icon,
                            text: bounty.tierInfo(theme).name,
                            color: bounty.tierInfo(theme).textColor,
                            backgroundColor:
                                bounty.tierInfo(theme).backgroundColor,
                            textColor: bounty.tierInfo(theme).textColor,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (bounty.rawStatus == 'AwaitingFunding') ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (bounty.totalCharged == null ||
                          bounty.paymentTimeoutExpiresAt == null) {
                        NotificationService.showError(
                            'Funding information is not available for this bounty.');
                        return;
                      }

                      final apiService =
                          Provider.of<ApiService>(context, listen: false);
                      try {
                        final config = await apiService.fetchAppConfig();
                        final walletAddress = config['escrow_wallet'];
                        final usdcMintAddress = config['usdc_mint_address'];

                        if (walletAddress == null || usdcMintAddress == null) {
                          throw Exception('Configuration is missing');
                        }

                        showDialog(
                          context: context,
                          builder: (context) => FundingQrDialog(
                            bountyId: bounty.id,
                            totalCharged: bounty.totalCharged!,
                            paymentTimeoutExpiresAt:
                                bounty.paymentTimeoutExpiresAt!,
                            walletAddress: walletAddress,
                            usdcMintAddress: usdcMintAddress,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not load funding information: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Fund Bounty'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
