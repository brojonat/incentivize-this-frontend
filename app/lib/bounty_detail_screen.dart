import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'bounty.dart';
import 'claim_dialog.dart';
import 'info_chip.dart';
import 'api_service.dart';
import 'paid_bounty_item.dart';
import 'loading_indicator.dart';

class BountyDetailScreen extends StatefulWidget {
  final Bounty bounty;
  final String? walletAddress;
  final Function(String contentId, String walletAddress) onSubmitClaim;

  const BountyDetailScreen({
    super.key,
    required this.bounty,
    this.walletAddress,
    required this.onSubmitClaim,
  });

  @override
  State<BountyDetailScreen> createState() => _BountyDetailScreenState();
}

class _BountyDetailScreenState extends State<BountyDetailScreen> {
  late final ApiService _apiService;
  List<PaidBountyItem> _paidItemsForWorkflow = [];
  bool _isLoadingPaidItems = true;
  String? _paidItemsError;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _fetchPaidItemsForWorkflow();
  }

  Future<void> _fetchPaidItemsForWorkflow() async {
    setState(() {
      _isLoadingPaidItems = true;
      _paidItemsError = null;
    });
    try {
      final items = await _apiService.fetchPaidBountiesForWorkflow(
          bountyId: widget.bounty.id);
      if (mounted) {
        setState(() {
          _paidItemsForWorkflow = items;
          _isLoadingPaidItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paidItemsError = 'Failed to load paid items: ${e.toString()}';
          _isLoadingPaidItems = false;
        });
      }
    }
  }

  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ClaimDialog(
        bounty: widget.bounty,
        initialWalletAddress: widget.walletAddress,
        onSubmit: widget.onSubmitClaim,
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

  // Helper Widget to build a tile for a paid bounty (similar to HomeScreen)
  Widget _buildPaidBountyTile(ThemeData theme, PaidBountyItem item) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.secondary,
        child: Icon(Icons.receipt_long, size: 20),
      ),
      title: Text(
        item.formattedAmount,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.formattedTimestamp,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      // Optionally, display memo or link to transaction if available
      // trailing: item.memo != null ? Text(item.memo!) : null,
    );
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
                            '${widget.bounty.bountyPerPost.toStringAsFixed(2)} per post',
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.device_hub_outlined,
                        text: widget.bounty.platformType,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.article_outlined,
                        text: widget.bounty.contentKind,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: widget.bounty.remainingPostsDisplay,
                        color: theme.colorScheme.secondary,
                      ),
                      if (widget.bounty.deadline != null &&
                          widget.bounty.deadline!.year > 1970) ...[
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
                                dateFormat.format(widget.bounty.deadline!),
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
                          color: widget.bounty.isActive
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.bounty.isActive
                                  ? Icons.verified_outlined
                                  : Icons.hourglass_empty,
                              size: 16,
                              color: widget.bounty.isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.bounty.isActive ? 'Active' : 'Closed',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.bounty.isActive
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
                    _formatRequirements(widget.bounty.description),
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

            // Paid Items for this Workflow Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Recent Claims for this Bounty',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingPaidItems)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: LoadingIndicator(message: 'Loading claims...'),
              )
            else if (_paidItemsError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    _paidItemsError!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_paidItemsForWorkflow.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 16.0),
                child: Center(
                  child: Text(
                    'No claims have been paid for this bounty yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap:
                    true, // Important for ListView inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                itemCount: _paidItemsForWorkflow.length,
                itemBuilder: (context, index) {
                  final item = _paidItemsForWorkflow[index];
                  return _buildPaidBountyTile(theme, item);
                },
              ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
      bottomNavigationBar: widget.bounty.isActive
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
